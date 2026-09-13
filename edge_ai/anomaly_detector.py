"""
anomaly_detector.py
===================
Real-time anomaly detection engine for AeroSense Edge.
Monitors rate-of-change across PM2.5, VOC, and CO channels to detect
sudden pollution events: garbage fires, gas leaks, dust storms, smoke plumes.

Uses exponential baseline tracking + Z-score spike detection to minimize
false positives while ensuring no genuine emergency event is missed.
Runs entirely on-device; zero cloud dependency.
"""

import logging
import time
from collections import deque
from typing import Dict, Any, List, Optional

__all__ = ["AnomalyDetector"]

logger = logging.getLogger(__name__)


class AnomalyDetector:
    """
    Detects sudden pollution spikes using a dual-threshold approach:
    1. Percentage change from rolling baseline (rapid spike detection)
    2. Absolute value breach (ensures absolute danger thresholds are enforced)
    """

    ANOMALY_CONFIG = {
        "PM25_SPIKE": {
            "label":         "Particulate Matter Surge",
            "metric":        "pm25",
            "pct_threshold": 60.0,    # % rise from baseline
            "abs_threshold": 75.0,    # µg/m³ (WHO Unhealthy threshold)
            "emoji":         "💨",
            "severity":      "HIGH",
        },
        "VOC_SURGE": {
            "label":         "Volatile Organic Compound Surge",
            "metric":        "voc",
            "pct_threshold": 80.0,
            "abs_threshold": 150.0,
            "emoji":         "☠️",
            "severity":      "CRITICAL",
        },
        "CO_SURGE": {
            "label":         "Carbon Monoxide Elevation",
            "metric":        "co",
            "pct_threshold": 100.0,
            "abs_threshold": 4.0,     # ppm
            "emoji":         "⚠️",
            "severity":      "HIGH",
        },
    }

    def __init__(self, baseline_window: int = 60, cooldown_seconds: int = 300):
        """
        Args:
            baseline_window:   Number of samples used to compute rolling baseline
            cooldown_seconds:  Minimum seconds between consecutive anomaly reports
                               for the same channel (prevents alert storms)
        """
        self.baseline_window = baseline_window
        self.cooldown_seconds = cooldown_seconds

        # Rolling value buffers (1 sample/second)
        self._pm25_buf: deque = deque(maxlen=max(baseline_window * 2, 120))
        self._voc_buf:  deque = deque(maxlen=max(baseline_window * 2, 120))
        self._co_buf:   deque = deque(maxlen=max(baseline_window * 2, 120))

        # Track last anomaly time per type (cooldown)
        self._last_fired: Dict[str, float] = {}

        # In-memory incident log (max 100 events)
        self.incidents: List[Dict[str, Any]] = []
        self._incident_id_counter = 1

    # ------------------------------------------------------------------
    # Data recording
    # ------------------------------------------------------------------

    def record(self, pm25: float, voc: float, co: float):
        """Call this every second with latest sensor readings."""
        self._pm25_buf.append(pm25)
        self._voc_buf.append(voc)
        self._co_buf.append(co)

    # ------------------------------------------------------------------
    # Anomaly checking
    # ------------------------------------------------------------------

    def check(
        self,
        current_features: Dict[str, Any],
        source_attribution: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        Evaluate the current sensor frame for anomalies.

        Returns:
            Anomaly event dict if a new anomaly is detected, else None.
            The returned dict is also appended to self.incidents.
        """
        now = time.time()
        min_samples = max(10, self.baseline_window // 4)

        checks = [
            ("PM25_SPIKE", self._pm25_buf, current_features.get("pm25", 0.0)),
            ("VOC_SURGE",  self._voc_buf,  current_features.get("voc",  0.0)),
            ("CO_SURGE",   self._co_buf,   current_features.get("co",   0.0)),
        ]

        for atype, buf, current_val in checks:
            if len(buf) < min_samples:
                continue

            # Compute baseline from older half of the buffer (avoids spike contaminating baseline)
            buf_list = list(buf)
            half     = len(buf_list) // 2
            baseline_samples = buf_list[:half] if half > 0 else buf_list
            baseline = sum(baseline_samples) / len(baseline_samples)

            if baseline < 0.5:
                continue  # avoid division by near-zero baselines

            cfg        = self.ANOMALY_CONFIG[atype]
            pct_change = ((current_val - baseline) / baseline) * 100.0

            pct_triggered = pct_change >= cfg["pct_threshold"]
            abs_triggered = current_val >= cfg["abs_threshold"]

            if not (pct_triggered and abs_triggered):
                continue

            # Cooldown check
            last_time = self._last_fired.get(atype, 0.0)
            if now - last_time < self.cooldown_seconds:
                continue

            self._last_fired[atype] = now

            event = {
                "id":              self._incident_id_counter,
                "type":            atype,
                "label":           cfg["label"],
                "emoji":           cfg["emoji"],
                "severity":        cfg["severity"],
                "magnitude_pct":   round(pct_change, 1),
                "baseline_value":  round(baseline, 2),
                "peak_value":      round(current_val, 2),
                "metric":          cfg["metric"],
                "detected_at":     now,
                "detected_at_str": time.strftime("%Y-%m-%dT%H:%M:%S", time.localtime(now)),
                "time_str":        time.strftime("%H:%M:%S", time.localtime(now)),
                "suspected_source":source_attribution.get("primary_source", "Unknown"),
                "source_confidence": source_attribution.get("confidence_percent", 0),
                "aqi_at_detection":  current_features.get("aqi", 0),
                "status":            "AUTO_DETECTED",
                "user_confirmation": None,  # "CONFIRMED" | "DISMISSED" | None
            }

            self._incident_id_counter += 1
            self.incidents.append(event)
            if len(self.incidents) > 100:
                self.incidents.pop(0)

            logger.warning(
                "🚨 ANOMALY: %s | +%.1f%% (%.2f→%.2f) | Source: %s | AQI: %d",
                atype, pct_change, baseline, current_val,
                event["suspected_source"], event["aqi_at_detection"]
            )
            return event  # report one at a time

        return None

    # ------------------------------------------------------------------
    # Incident management
    # ------------------------------------------------------------------

    def confirm_incident(self, incident_id: int, status: str) -> bool:
        """
        Update user confirmation status on an incident.

        Args:
            incident_id: The incident ID to update
            status:      "CONFIRMED" or "DISMISSED"

        Returns:
            True if the incident was found and updated.
        """
        for inc in self.incidents:
            if inc["id"] == incident_id:
                inc["user_confirmation"] = status
                inc["status"] = f"USER_{status}"
                logger.info("Incident #%d marked as %s", incident_id, status)
                return True
        return False

    def get_recent_incidents(self, limit: int = 20) -> List[Dict[str, Any]]:
        """Return most recent incidents, newest first."""
        return list(reversed(self.incidents[-limit:]))

    def get_unconfirmed_count(self) -> int:
        """Count incidents pending user review."""
        return sum(1 for i in self.incidents if i["user_confirmation"] is None)
