"""
smart_notification_filter.py
=============================
ML-driven alert suppression for AeroSense Edge v1.5.0.

Prevents notification fatigue by:
  1. Building a per-hour BASELINE of expected pollution levels (rolling 7-day avg)
  2. Only alerting when a reading is ANOMALOUS vs the historical baseline
  3. Applying EXPONENTIAL BACK-OFF when the same alert fires repeatedly
  4. Computing an ALERT FATIGUE SCORE (0–100) so users and admins can tune sensitivity

Key concepts:
  - Anomaly threshold: reading > (baseline_mean + N * baseline_std)
  - Fatigue score: rises +10 per alert, decays -1/minute towards zero
  - When fatigue >= fatigue_cap, alerts are suppressed until cool-down

Runs 100% on-device. Zero cloud dependency.
"""

import logging
import math
import time
from collections import defaultdict, deque
from typing import Dict, Any, List, Optional, Tuple

__all__ = ["SmartNotificationFilter"]

logger = logging.getLogger(__name__)


class SmartNotificationFilter:
    """
    On-device smart alert suppression engine.

    Usage:
        snf = SmartNotificationFilter()
        snf.record_baseline("pm25", 28.5, hour=9)
        should_fire, reason = snf.should_alert("pm25", 95.0)
        if should_fire:
            send_notification(...)
    """

    # Number of standard deviations above baseline to consider anomalous
    DEFAULT_SIGMA_THRESHOLD = 2.5

    # Alert fatigue: rises by this on each fired alert
    FATIGUE_PER_ALERT = 12

    # Fatigue decay per minute of silence
    FATIGUE_DECAY_PER_MIN = 1.5

    # When fatigue >= this, suppress all non-critical alerts
    DEFAULT_FATIGUE_CAP = 70

    # Minimum interval between same-metric alerts (seconds)
    DEFAULT_COOLDOWN_SEC = 300   # 5 minutes

    # Baseline window: keep up to 168 readings per hour (7 days × 24 hours)
    _BASELINE_MAXLEN = 168

    def __init__(
        self,
        sigma_threshold: float = DEFAULT_SIGMA_THRESHOLD,
        fatigue_cap:     int   = DEFAULT_FATIGUE_CAP,
        cooldown_sec:    int   = DEFAULT_COOLDOWN_SEC,
    ):
        self.sigma_threshold = sigma_threshold
        self.fatigue_cap     = fatigue_cap
        self.cooldown_sec    = cooldown_sec

        # baseline[metric][hour] = deque of float readings
        self._baseline: Dict[str, Dict[int, deque]] = defaultdict(
            lambda: defaultdict(lambda: deque(maxlen=self._BASELINE_MAXLEN))
        )

        # Alert fatigue score (0–100)
        self._fatigue_score:    float = 0.0
        self._last_fatigue_ts:  float = time.time()

        # Per-metric last alert timestamps for cooldown
        self._last_alert_ts: Dict[str, float] = {}

        # Alert history for the /api/notification-intelligence endpoint
        self._alert_history: deque = deque(maxlen=50)

        # Suppression event history
        self._suppression_history: deque = deque(maxlen=20)

        # Total counters
        self._total_fired:      int = 0
        self._total_suppressed: int = 0

    # ------------------------------------------------------------------
    # Baseline Recording (call every second from telemetry loop)
    # ------------------------------------------------------------------

    def record_baseline(self, metric: str, value: float, hour: Optional[int] = None):
        """
        Feed a live reading into the per-metric per-hour baseline.
        Call this for every sensor reading to build robust statistics.

        Args:
            metric: sensor name e.g. "pm25", "co2", "voc", "aqi"
            value:  current reading
            hour:   override current hour (0–23), defaults to system time
        """
        h = hour if hour is not None else int(time.strftime("%H"))
        self._baseline[metric][h].append(value)

    # ------------------------------------------------------------------
    # Alert Decision (call when considering triggering an alert)
    # ------------------------------------------------------------------

    def should_alert(
        self,
        metric: str,
        value: float,
        severity: str = "moderate",   # "low" | "moderate" | "high" | "critical"
        hour: Optional[int] = None,
    ) -> Tuple[bool, str]:
        """
        Decide whether an alert should fire for (metric, value).

        Args:
            metric:   "pm25", "aqi", "co2", "voc", etc.
            value:    current reading that triggered the rule
            severity: alert severity — "critical" bypasses fatigue suppression
            hour:     override current hour

        Returns:
            (should_fire: bool, reason: str)
        """
        h = hour if hour is not None else int(time.strftime("%H"))
        self._decay_fatigue()

        # CRITICAL alerts always fire regardless of fatigue
        if severity == "critical":
            self._record_fired(metric, value, severity, "Critical — bypassed suppression")
            return True, "critical_bypass"

        # 1. Cooldown check
        last_ts = self._last_alert_ts.get(metric, 0)
        elapsed = time.time() - last_ts
        if elapsed < self.cooldown_sec:
            remaining = int(self.cooldown_sec - elapsed)
            reason = f"cooldown ({remaining}s remaining)"
            self._record_suppressed(metric, value, reason)
            return False, reason

        # 2. Fatigue check
        if self._fatigue_score >= self.fatigue_cap:
            reason = f"fatigue_suppressed (score={self._fatigue_score:.0f}/{self.fatigue_cap})"
            self._record_suppressed(metric, value, reason)
            return False, reason

        # 3. Baseline anomaly check
        is_anomalous, anomaly_score, baseline_mean, baseline_std = \
            self._check_anomaly(metric, value, h)

        if not is_anomalous:
            reason = (
                f"baseline_normal (value={value:.1f}, mean={baseline_mean:.1f}, "
                f"std={baseline_std:.1f}, threshold={baseline_mean + self.sigma_threshold * baseline_std:.1f})"
            )
            self._record_suppressed(metric, value, reason)
            return False, reason

        # Alert fires!
        reason = (
            f"anomaly_detected (score={anomaly_score:.1f}σ, "
            f"value={value:.1f} vs baseline {baseline_mean:.1f}±{baseline_std:.1f})"
        )
        self._record_fired(metric, value, severity, reason)
        return True, reason

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _check_anomaly(
        self, metric: str, value: float, hour: int
    ) -> Tuple[bool, float, float, float]:
        """
        Returns (is_anomalous, sigma_score, baseline_mean, baseline_std).
        If no baseline exists yet, always returns anomalous (fire the alert).
        """
        readings = list(self._baseline[metric].get(hour, []))
        if len(readings) < 5:
            # Insufficient history — treat as anomalous (don't miss early alerts)
            return True, 99.0, value, 0.0

        mean = sum(readings) / len(readings)
        variance = sum((r - mean) ** 2 for r in readings) / len(readings)
        std = math.sqrt(variance) if variance > 0 else 1.0

        sigma_score = (value - mean) / std if std > 0 else 0.0
        is_anomalous = sigma_score >= self.sigma_threshold
        return is_anomalous, sigma_score, mean, std

    def _decay_fatigue(self):
        """Decay fatigue score based on elapsed time since last update."""
        now = time.time()
        elapsed_min = (now - self._last_fatigue_ts) / 60.0
        decay = elapsed_min * self.FATIGUE_DECAY_PER_MIN
        self._fatigue_score = max(0.0, self._fatigue_score - decay)
        self._last_fatigue_ts = now

    def _record_fired(self, metric: str, value: float, severity: str, reason: str):
        self._fatigue_score = min(100.0, self._fatigue_score + self.FATIGUE_PER_ALERT)
        self._last_alert_ts[metric] = time.time()
        self._total_fired += 1
        self._alert_history.append({
            "ts":       time.strftime("%Y-%m-%dT%H:%M:%S"),
            "metric":   metric,
            "value":    round(value, 1),
            "severity": severity,
            "reason":   reason,
            "type":     "fired",
        })
        logger.info("SmartNotificationFilter: ALERT FIRED — %s=%.1f (%s)", metric, value, reason)

    def _record_suppressed(self, metric: str, value: float, reason: str):
        self._total_suppressed += 1
        self._suppression_history.append({
            "ts":     time.strftime("%Y-%m-%dT%H:%M:%S"),
            "metric": metric,
            "value":  round(value, 1),
            "reason": reason,
        })
        logger.debug("SmartNotificationFilter: suppressed %s=%.1f (%s)", metric, value, reason)

    # ------------------------------------------------------------------
    # Status & API
    # ------------------------------------------------------------------

    def get_status(self) -> Dict[str, Any]:
        """Return full status for /api/notification-intelligence endpoint."""
        self._decay_fatigue()

        # Compute baseline summary per metric
        baseline_summary = {}
        for metric, hour_dict in self._baseline.items():
            all_vals = []
            for readings in hour_dict.values():
                all_vals.extend(readings)
            if all_vals:
                mean = sum(all_vals) / len(all_vals)
                baseline_summary[metric] = {
                    "mean":    round(mean, 1),
                    "samples": len(all_vals),
                }

        fatigue_label = self._fatigue_label(self._fatigue_score)

        return {
            "fatigue_score":       round(self._fatigue_score, 1),
            "fatigue_cap":         self.fatigue_cap,
            "fatigue_label":       fatigue_label,
            "fatigue_pct":         round((self._fatigue_score / self.fatigue_cap) * 100, 1),
            "sigma_threshold":     self.sigma_threshold,
            "cooldown_sec":        self.cooldown_sec,
            "total_fired":         self._total_fired,
            "total_suppressed":    self._total_suppressed,
            "suppression_rate":    self._suppression_rate(),
            "recent_alerts":       list(self._alert_history)[-10:],
            "recent_suppressions": list(self._suppression_history)[-5:],
            "baseline_summary":    baseline_summary,
        }

    def configure(self, sigma_threshold: float = None, fatigue_cap: int = None,
                  cooldown_sec: int = None):
        """Dynamically reconfigure filter parameters (from settings API)."""
        if sigma_threshold is not None:
            self.sigma_threshold = max(0.5, min(10.0, sigma_threshold))
        if fatigue_cap is not None:
            self.fatigue_cap = max(10, min(100, fatigue_cap))
        if cooldown_sec is not None:
            self.cooldown_sec = max(30, min(3600, cooldown_sec))
        logger.info(
            "SmartNotificationFilter reconfigured: sigma=%.1f fatigue_cap=%d cooldown=%ds",
            self.sigma_threshold, self.fatigue_cap, self.cooldown_sec
        )

    def reset_fatigue(self):
        """Manually reset alert fatigue (e.g. after genuine emergency resolved)."""
        self._fatigue_score = 0.0
        logger.info("SmartNotificationFilter: fatigue reset to 0")

    def _suppression_rate(self) -> float:
        total = self._total_fired + self._total_suppressed
        if total == 0:
            return 0.0
        return round((self._total_suppressed / total) * 100.0, 1)

    def _fatigue_label(self, score: float) -> str:
        if score < 20:  return "🟢 Alert-Ready"
        if score < 40:  return "🟡 Mild Fatigue"
        if score < 60:  return "🟠 Moderate Fatigue"
        if score < 80:  return "🔴 High Fatigue"
        return "🚨 Suppressed"
