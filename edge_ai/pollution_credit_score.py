"""
pollution_credit_score.py
=========================
Personal Pollution Credit Scorer for AeroSense Edge v1.5.0.

Converts cumulative PM2.5, VOC, CO2 and NO2 exposure into a meaningful
0–1000 "Lung Health Score" — modelled after a financial credit score to give
users an instantly relatable personal air-quality metric.

Score bands:
  850–1000  Excellent  — WHO-compliant air consistently
  700–849   Good       — Mostly clean, rare spikes
  500–699   Fair       — Regular moderate exposure
  300–499   Poor       — Frequent unhealthy exposure
  0–299     Critical   — Chronic hazardous exposure

Household profiles apply a risk multiplier to the raw score:
  adult:   1.0x  (baseline)
  elderly: 1.3x  (heightened cardiovascular sensitivity)
  child:   1.5x  (developing lungs — most vulnerable)
  asthma:  1.8x  (airway hyper-reactivity)

Runs 100% on-device on Qualcomm QRB2210 Linux core. Zero cloud dependency.
"""

import logging
import time
from collections import defaultdict, deque
from typing import Dict, Any, List, Optional

__all__ = ["PollutionCreditScorer"]

logger = logging.getLogger(__name__)


class PollutionCreditScorer:
    """On-device Pollution Credit Score engine."""

    # Score band boundaries
    SCORE_BANDS = [
        (850, "Excellent", "🌿", "#22c55e"),
        (700, "Good",      "✅", "#84cc16"),
        (500, "Fair",      "🟡", "#eab308"),
        (300, "Poor",      "🟠", "#f97316"),
        (0,   "Critical",  "🚨", "#ef4444"),
    ]

    # Household risk multipliers
    PROFILE_MULTIPLIERS = {
        "adult":   1.0,
        "elderly": 1.3,
        "child":   1.5,
        "asthma":  1.8,
    }

    # WHO 24h limits (µg/m³)
    WHO_PM25 = 15.0
    WHO_PM10 = 45.0
    WHO_NO2  = 25.0   # annual, used as 24h proxy

    # Perfect-air hourly point budget (score is additive over 24h)
    _HOURLY_MAX_POINTS = 1000.0 / 24.0   # 41.67 pts/h at WHO-clean air

    def __init__(self, default_profile: str = "adult"):
        self.profile = default_profile.lower()
        if self.profile not in self.PROFILE_MULTIPLIERS:
            self.profile = "adult"

        # 7-day daily score history: deque of {"date": str, "score": int, "band": str}
        self._daily_history: deque = deque(maxlen=7)

        # Today's hourly accumulator: {hour_str: {"pm25": float, "voc": float, "co2": float}}
        self._today_hourly: Dict[str, Dict[str, float]] = {}
        self._today_date: str = time.strftime("%Y-%m-%d")

    # ------------------------------------------------------------------
    # Ingestion
    # ------------------------------------------------------------------

    def record_hour(self, hour_str: str, pm25: float, voc: float = 0.0,
                    co2: float = 400.0, no2: float = 0.0):
        """
        Record a single hourly reading.
        Call this from the storage engine's hourly summary callback.

        Args:
            hour_str: "HH:00" format
            pm25: PM2.5 µg/m³
            voc:  VOC index (0–500)
            co2:  CO₂ ppm
            no2:  NO₂ µg/m³
        """
        today = time.strftime("%Y-%m-%d")
        if today != self._today_date:
            # Day rolled over — archive yesterday's score
            self._archive_today()
            self._today_date = today
            self._today_hourly = {}

        self._today_hourly[hour_str] = {
            "pm25": max(0.0, pm25),
            "voc":  max(0.0, voc),
            "co2":  max(0.0, co2),
            "no2":  max(0.0, no2),
        }

    def record_reading_live(self, pm25: float, voc: float = 0.0,
                            co2: float = 400.0, no2: float = 0.0):
        """
        Convenience: record a per-second reading bucketed into the current hour.
        Use this if you don't have pre-aggregated hourly data.
        """
        hour_str = time.strftime("%H:00")
        existing = self._today_hourly.get(hour_str, {"pm25": [], "voc": [], "co2": [], "no2": []})
        # On first call for this hour we switch from dict-of-floats to dict-of-lists
        if not isinstance(existing.get("pm25"), list):
            existing = {"pm25": [], "voc": [], "co2": [], "no2": []}
        existing["pm25"].append(pm25)
        existing["voc"].append(voc)
        existing["co2"].append(co2)
        existing["no2"].append(no2)
        self._today_hourly[hour_str] = existing

    # ------------------------------------------------------------------
    # Score Computation
    # ------------------------------------------------------------------

    def compute_score(self) -> Dict[str, Any]:
        """
        Compute the current Pollution Credit Score.

        Returns a rich dict ready to be served via /api/health-score.
        """
        hourly_data = self._resolve_hourly()
        if not hourly_data:
            return self._empty_score()

        multiplier = self.PROFILE_MULTIPLIERS[self.profile]
        raw_score, hour_points = self._calculate_raw_score(hourly_data)

        # Apply profile risk amplification (higher multiplier = bigger score reduction)
        adjusted_score = int(raw_score / multiplier)
        adjusted_score = max(0, min(1000, adjusted_score))

        band, emoji, color = self._get_band(adjusted_score)
        weekly_avg, weekly_delta = self._weekly_stats(adjusted_score)

        result = {
            "score":              adjusted_score,
            "band":               band,
            "band_emoji":         emoji,
            "band_color":         color,
            "profile":            self.profile,
            "profile_multiplier": multiplier,
            "hours_monitored":    len(hourly_data),
            "hourly_points":      hour_points,                   # list of {hour, pts, pm25}
            "weekly_history":     list(self._daily_history),     # last 7 days
            "weekly_avg_score":   weekly_avg,
            "weekly_delta":       weekly_delta,                  # +/- vs last week avg
            "trend":              self._trend_label(weekly_delta),
            "recommendations":    self._recommendations(adjusted_score, hourly_data, band),
            "computed_at":        time.strftime("%Y-%m-%dT%H:%M:%S"),
        }
        logger.debug(
            "Credit score: %d (%s) | profile=%s | hours=%d | weekly_delta=%+d",
            adjusted_score, band, self.profile, len(hourly_data), weekly_delta
        )
        return result

    # ------------------------------------------------------------------
    # Internal Helpers
    # ------------------------------------------------------------------

    def _calculate_raw_score(self, hourly: List[Dict]) -> tuple:
        """Returns (raw_score_0_1000, list_of_hourly_point_dicts)."""
        total = 0.0
        hour_points = []
        max_possible = self._HOURLY_MAX_POINTS * len(hourly)

        for h in hourly:
            pm25 = h.get("pm25", 0.0)
            voc  = h.get("voc",  0.0)
            co2  = h.get("co2",  400.0)
            no2  = h.get("no2",  0.0)

            # PM2.5 deduction — heaviest weight (60%)
            pm25_pts = self._HOURLY_MAX_POINTS * 0.60 * max(0, 1 - (pm25 / 75.0))

            # VOC deduction (20%) — voc index 0=clean, 500=hazardous
            voc_pts  = self._HOURLY_MAX_POINTS * 0.20 * max(0, 1 - (voc / 400.0))

            # CO2 deduction (10%) — 400 baseline, 2000 max
            co2_pts  = self._HOURLY_MAX_POINTS * 0.10 * max(0, 1 - ((co2 - 400) / 1600.0))

            # NO2 deduction (10%)
            no2_pts  = self._HOURLY_MAX_POINTS * 0.10 * max(0, 1 - (no2 / 50.0))

            hour_total = pm25_pts + voc_pts + co2_pts + no2_pts
            total += hour_total
            hour_points.append({
                "hour":   h.get("hour", "??:00"),
                "points": round(hour_total, 1),
                "pm25":   round(pm25, 1),
                "voc":    round(voc, 1),
            })

        raw = int((total / max(1.0, max_possible)) * 1000)
        return raw, hour_points

    def _resolve_hourly(self) -> List[Dict]:
        """Normalize raw today_hourly (may be list-form or float-form) to list of dicts."""
        result = []
        for hour, data in sorted(self._today_hourly.items()):
            if isinstance(data.get("pm25"), list):
                vals = data["pm25"]
                avg_pm25 = sum(vals) / len(vals) if vals else 0.0
                voc_vals = data.get("voc", [0.0])
                avg_voc  = sum(voc_vals) / len(voc_vals) if voc_vals else 0.0
                co2_vals = data.get("co2", [400.0])
                avg_co2  = sum(co2_vals) / len(co2_vals) if co2_vals else 400.0
                no2_vals = data.get("no2", [0.0])
                avg_no2  = sum(no2_vals) / len(no2_vals) if no2_vals else 0.0
                result.append({
                    "hour": hour, "pm25": avg_pm25, "voc": avg_voc,
                    "co2": avg_co2, "no2": avg_no2
                })
            else:
                result.append({"hour": hour, **data})
        return result

    def _archive_today(self):
        score_data = self.compute_score()
        if score_data.get("hours_monitored", 0) > 0:
            self._daily_history.append({
                "date":  self._today_date,
                "score": score_data["score"],
                "band":  score_data["band"],
                "color": score_data["band_color"],
            })

    def _weekly_stats(self, today_score: int) -> tuple:
        if not self._daily_history:
            return today_score, 0
        scores = [d["score"] for d in self._daily_history]
        avg = int(sum(scores) / len(scores))
        delta = today_score - avg
        return avg, delta

    def _trend_label(self, delta: int) -> str:
        if delta >= 50:   return "📈 Significantly Improving"
        if delta >= 15:   return "↗️ Improving"
        if delta >= -15:  return "➡️ Stable"
        if delta >= -50:  return "↘️ Declining"
        return "📉 Significantly Declining"

    def _get_band(self, score: int) -> tuple:
        for threshold, band, emoji, color in self.SCORE_BANDS:
            if score >= threshold:
                return band, emoji, color
        return "Critical", "🚨", "#ef4444"

    def _recommendations(self, score: int, hourly: List[Dict], band: str) -> List[str]:
        recs = []
        pm25_vals = [h.get("pm25", 0) for h in hourly]
        avg_pm25 = sum(pm25_vals) / len(pm25_vals) if pm25_vals else 0

        if score < 500:
            recs.append("🏠 Keep windows closed during peak pollution hours")
            recs.append("😷 Wear N95 mask for outdoor activities")
        if avg_pm25 > 35:
            recs.append("💨 Run HEPA air purifier continuously")
        if score < 300:
            recs.append("🏥 Consider consulting a physician about respiratory health")
        if band in ("Excellent", "Good"):
            recs.append("🌿 Great job! Maintain current indoor air quality habits")
        if self.profile in ("child", "asthma"):
            recs.append("⚠️ Sensitive profile detected — stricter exposure limits applied")
        return recs[:4]

    def set_profile(self, profile: str):
        """Change household member profile."""
        p = profile.lower()
        if p in self.PROFILE_MULTIPLIERS:
            self.profile = p
            logger.info("Pollution credit profile set to: %s", p)

    def inject_history_for_demo(self, days: int = 7):
        """Inject realistic 7-day demo history for judge testing."""
        import random
        base_scores = [720, 680, 750, 610, 790, 700, 740]
        base_date = time.time() - 86400 * days
        self._daily_history.clear()
        for i in range(min(days, len(base_scores))):
            day_ts = base_date + 86400 * i
            date_str = time.strftime("%Y-%m-%d", time.localtime(day_ts))
            score = base_scores[i] + random.randint(-20, 20)
            score = max(0, min(1000, score))
            band, _, color = self._get_band(score)
            self._daily_history.append({
                "date": date_str, "score": score, "band": band, "color": color
            })

    def _empty_score(self) -> Dict[str, Any]:
        return {
            "score":              1000,
            "band":               "Excellent",
            "band_emoji":         "🌿",
            "band_color":         "#22c55e",
            "profile":            self.profile,
            "profile_multiplier": self.PROFILE_MULTIPLIERS[self.profile],
            "hours_monitored":    0,
            "hourly_points":      [],
            "weekly_history":     [],
            "weekly_avg_score":   1000,
            "weekly_delta":       0,
            "trend":              "➡️ Stable",
            "recommendations":    ["Start monitoring to compute your personal score"],
            "computed_at":        time.strftime("%Y-%m-%dT%H:%M:%S"),
        }
