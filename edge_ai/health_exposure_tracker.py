"""
health_exposure_tracker.py
==========================
Cumulative personal health exposure tracker for AeroSense Edge.
Converts abstract PM2.5 sensor readings into personally meaningful metrics:
  - Cigarette Equivalent (based on Zheng et al. 2015 epidemiological research)
  - Daily Health Point deduction/gain system
  - WHO 2021 compliance percentage
  - Lung Load Score (0-100 visual indicator)
  - Hourly source-aware exposure breakdown

Runs 100% on-device on Qualcomm QRB2210 Linux core.
"""

import logging
import time
from collections import defaultdict
from typing import Dict, Any, List, Optional

__all__ = ["HealthExposureTracker"]

logger = logging.getLogger(__name__)


class HealthExposureTracker:
    # WHO 2021 guidelines
    WHO_PM25_24H_LIMIT   = 15.0   # µg/m³
    WHO_PM25_ANNUAL_LIMIT = 5.0   # µg/m³

    # Research basis: 22 µg/m³ PM2.5 sustained for 24h ≈ 1 cigarette
    # Source: Zheng et al. (2015), Berkeley Air Quality Lab equivalence
    CIGARETTE_PM25_24H_EQUIV = 22.0  # µg/m³ for 24h = 1 cigarette

    # Health Points per hour of exposure (positive = gain, negative = loss)
    _HP_TABLE = [
        (15.0,  "Good",      +2,  "🌿 Excellent air — lungs recovering"),
        (35.0,  "Moderate",  -1,  "🟡 Mild irritation for sensitive groups"),
        (55.0,  "Poor",      -4,  "🟠 Noticeable respiratory stress"),
        (75.0,  "Unhealthy", -8,  "🔴 Significant health impact"),
        (150.0, "Very Poor", -15, "⚠️ Severe — limit all outdoor activity"),
        (float('inf'), "Hazardous", -25, "🚨 Emergency-level pollution"),
    ]

    def __init__(self):
        # Rolling 24-hour buffer: list of {"ts": float, "pm25": float, "source": str}
        self._readings: List[Dict[str, Any]] = []

    # ------------------------------------------------------------------
    # Data ingestion
    # ------------------------------------------------------------------

    def record_reading(self, pm25: float, source: str, timestamp: float = None):
        """Record a PM2.5 reading for cumulative tracking. Call every second."""
        if timestamp is None:
            timestamp = time.time()
        self._readings.append({"ts": timestamp, "pm25": pm25, "source": source})
        self._prune_old_readings()

    def _prune_old_readings(self):
        cutoff = time.time() - 86400  # keep last 24h
        self._readings = [r for r in self._readings if r["ts"] > cutoff]

    # ------------------------------------------------------------------
    # Core computation
    # ------------------------------------------------------------------

    def compute_daily_exposure(
        self,
        hourly_data: Optional[List[Dict[str, Any]]] = None
    ) -> Dict[str, Any]:
        """
        Compute cumulative daily health exposure statistics.

        Args:
            hourly_data: Optional pre-aggregated list of
                         {"hour": "08:00", "pm25": float, "source": str}
                         from storage_engine. If None, uses internal buffer.

        Returns:
            Dict with cigarette_equivalent, health_points_delta, lung_load_score, etc.
        """
        if hourly_data is None:
            hourly_data = self._aggregate_to_hourly()

        if not hourly_data:
            return self._empty_stats()

        hours_monitored = len(hourly_data)
        pm25_values     = [h["pm25"] for h in hourly_data]
        avg_pm25        = sum(pm25_values) / hours_monitored

        # --- Cigarette Equivalent ---
        # Excess exposure = how much above WHO 24h limit (15 µg/m³)
        excess_per_hour = [max(0.0, v - self.WHO_PM25_24H_LIMIT) for v in pm25_values]
        total_excess_ug_h = sum(excess_per_hour)
        # Normalize: (CIGARETTE_EQUIV - WHO_LIMIT) * 24h = excess for 1 cigarette
        cig_excess_per_24h = (self.CIGARETTE_PM25_24H_EQUIV - self.WHO_PM25_24H_LIMIT) * 24.0
        cigarette_equivalent = round(total_excess_ug_h / max(1.0, cig_excess_per_24h), 2)

        # --- WHO Compliance ---
        compliant_hours = sum(1 for v in pm25_values if v <= self.WHO_PM25_24H_LIMIT)
        compliance_pct  = round((compliant_hours / hours_monitored) * 100.0, 1)

        # --- Lung Load Score (0–100 visual) ---
        # 0 = perfect air, 100 = 500 AQI hazardous
        lung_load = min(100, int((avg_pm25 / 75.0) * 100))

        # --- Health Points ---
        hp_delta, hp_log = self._compute_hp_and_log(pm25_values)

        # --- Source Breakdown ---
        source_counts: Dict[str, int] = defaultdict(int)
        for h in hourly_data:
            source_counts[h.get("source", "Unknown")] += 1
        source_counts = dict(source_counts)

        # --- Peak / Best Hours ---
        worst_hour = max(hourly_data, key=lambda h: h["pm25"])
        best_hour  = min(hourly_data, key=lambda h: h["pm25"])

        # --- Narrative ---
        narrative = self._build_narrative(
            cigarette_equivalent, avg_pm25, worst_hour, compliance_pct
        )

        result = {
            "date":                      time.strftime("%Y-%m-%d"),
            "hours_monitored":           hours_monitored,
            "avg_pm25_today":            round(avg_pm25, 1),
            "cumulative_excess_pm25_ug_h": round(total_excess_ug_h, 1),
            "cigarette_equivalent":      cigarette_equivalent,
            "health_points_delta":       hp_delta,
            "who_compliance_pct":        compliance_pct,
            "compliant_hours":           compliant_hours,
            "lung_load_score":           lung_load,
            "source_breakdown":          source_counts,
            "worst_hour":                worst_hour,
            "best_hour":                 best_hour,
            "hp_log":                    hp_log[-6:],   # last 6 events for UI
            "hourly_breakdown":          hourly_data,
            "exposure_narrative":        narrative,
        }
        logger.debug(
            "Health exposure: avg_pm25=%.1f cig_equiv=%.2f hp_delta=%d compliance=%.1f%%",
            avg_pm25, cigarette_equivalent, hp_delta, compliance_pct
        )
        return result

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _compute_hp_and_log(
        self, pm25_values: List[float]
    ) -> tuple[int, List[Dict[str, Any]]]:
        """Returns (total_hp_delta, list_of_hp_events)."""
        total  = 0
        events = []
        for pm25 in pm25_values:
            for limit, label, hp, message in self._HP_TABLE:
                if pm25 <= limit:
                    total += hp
                    if hp < 0:  # only log negative events (losses)
                        events.append({
                            "pm25":    round(pm25, 1),
                            "category": label,
                            "hp":      hp,
                            "message": message
                        })
                    break
        return total, events

    def _build_narrative(
        self,
        cigarettes: float,
        avg_pm25: float,
        worst_hour: Dict[str, Any],
        compliance_pct: float
    ) -> str:
        worst_time   = worst_hour.get("hour", "?")
        worst_source = worst_hour.get("source", "Unknown")

        if cigarettes < 0.05:
            return (
                f"Outstanding air quality today! PM2.5 averaged just {avg_pm25:.1f} µg/m³ — "
                f"well within WHO 24h guidelines. Your lungs are in great shape."
            )
        elif cigarettes < 0.5:
            return (
                f"Mild exposure today — equivalent to ~{cigarettes} cigarettes of PM2.5 "
                f"(avg {avg_pm25:.1f} µg/m³). WHO compliance: {compliance_pct}%. "
                f"Peak at {worst_time} ({worst_source})."
            )
        elif cigarettes < 2.0:
            return (
                f"Moderate exposure day. PM2.5 avg {avg_pm25:.1f} µg/m³ ≈ {cigarettes} cigarettes. "
                f"WHO compliance: {compliance_pct}%. Peak at {worst_time} ({worst_source}). "
                f"Consider limiting prolonged outdoor activities."
            )
        else:
            return (
                f"High exposure day! Today's PM2.5 (avg {avg_pm25:.1f} µg/m³) is equivalent "
                f"to ~{cigarettes} cigarettes. WHO compliance: only {compliance_pct}%. "
                f"Peak at {worst_time} ({worst_source}). Use N95 masks outdoors."
            )

    def _aggregate_to_hourly(self) -> List[Dict[str, Any]]:
        """Aggregate internal per-second readings into hourly averages."""
        hourly: Dict[str, Dict] = defaultdict(lambda: {"pm25_vals": [], "sources": []})
        for r in self._readings:
            hour_key = time.strftime("%H:00", time.localtime(r["ts"]))
            hourly[hour_key]["pm25_vals"].append(r["pm25"])
            hourly[hour_key]["sources"].append(r["source"])

        result = []
        for hour, data in sorted(hourly.items()):
            vals = data["pm25_vals"]
            avg  = sum(vals) / len(vals)
            dominant_src = max(set(data["sources"]), key=data["sources"].count)
            result.append({
                "hour":   hour,
                "pm25":   round(avg, 1),
                "source": dominant_src
            })
        return result

    def _empty_stats(self) -> Dict[str, Any]:
        return {
            "date":                      time.strftime("%Y-%m-%d"),
            "hours_monitored":           0,
            "avg_pm25_today":            0.0,
            "cumulative_excess_pm25_ug_h": 0.0,
            "cigarette_equivalent":      0.0,
            "health_points_delta":       0,
            "who_compliance_pct":        100.0,
            "compliant_hours":           0,
            "lung_load_score":           0,
            "source_breakdown":          {},
            "worst_hour":                None,
            "best_hour":                 None,
            "hp_log":                    [],
            "hourly_breakdown":          [],
            "exposure_narrative":        (
                "No readings collected yet today. "
                "Start monitoring to track your personal health exposure."
            ),
        }
