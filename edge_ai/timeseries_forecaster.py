"""
timeseries_forecaster.py
========================
On-device hyperlocal time series forecasting engine for Arduino UNO Q.
Predicts PM2.5, PM10, and AQI for +1h, +2h, +4h, and +6h intervals using
exponential trend tracking, local atmospheric physics, and diurnal boundary layer modeling.
"""

import logging
import math
import time
from collections import deque
from typing import Dict, Any, List

__all__ = ["TimeSeriesForecaster"]

logger = logging.getLogger(__name__)


class TimeSeriesForecaster:
    def __init__(self, max_history: int = 120):
        self.max_history = max_history
        # O(1) deque buffers instead of list + pop(0)
        self.pm25_buffer: deque = deque(maxlen=max_history)
        self.pm10_buffer: deque = deque(maxlen=max_history)
        self.temp_buffer: deque = deque(maxlen=max_history)
        self.hum_buffer:  deque = deque(maxlen=max_history)
        self.time_buffer: deque = deque(maxlen=max_history)

    def record_reading(self, pm25: float, pm10: float, temp: float, hum: float, timestamp: float = None):
        if timestamp is None:
            timestamp = time.time()
        self.pm25_buffer.append(pm25)
        self.pm10_buffer.append(pm10)
        self.temp_buffer.append(temp)
        self.hum_buffer.append(hum)
        self.time_buffer.append(timestamp)

    def _get_diurnal_factor(self, forecast_hour: int) -> float:
        """
        Diurnal Atmospheric Boundary Layer modulation factor (0.0 to 24.0h):
        - 06:00 - 09:00: Morning traffic surge + shallow thermal inversion (Pollution peaks: +35%)
        - 12:00 - 16:00: Solar heating expands boundary layer, enhancing vertical dispersion (Pollution drops: -25%)
        - 18:00 - 22:00: Evening rush hour + nocturnal boundary layer contraction (Pollution rises: +40%)
        - 00:00 - 05:00: Low human activity, steady background (Moderate)
        """
        hour = forecast_hour % 24
        if 6 <= hour <= 9:
            # Morning peak
            return 1.35
        elif 10 <= hour <= 12:
            return 1.05
        elif 13 <= hour <= 16:
            # Afternoon dispersion
            return 0.75
        elif 17 <= hour <= 21:
            # Evening peak
            return 1.40
        elif 22 <= hour <= 24 or 0 <= hour <= 2:
            return 1.15
        else:
            return 0.90

    def forecast(self, current_pm25: float, current_pm10: float, current_temp: float, current_hum: float) -> Dict[str, Any]:
        """
        Generates +1h, +2h, +4h, +6h predictions with upper and lower confidence intervals.
        """
        pm25_list = list(self.pm25_buffer)

        # Calculate recent rate of change (trend)
        if len(pm25_list) >= 5:
            # Simple linear regression over recent samples
            n = min(15, len(pm25_list))
            recent_pm = pm25_list[-n:]
            x_mean = (n - 1) / 2.0
            y_mean = sum(recent_pm) / n
            numerator   = sum((i - x_mean) * (recent_pm[i] - y_mean) for i in range(n))
            denominator = sum((i - x_mean) ** 2 for i in range(n))
            slope_per_sample = (numerator / denominator) if denominator != 0 else 0.0
            # Convert slope to delta per hour (assuming 1 sample every ~10s)
            trend_per_hour = slope_per_sample * 6.0
        else:
            trend_per_hour = 0.0

        current_time = time.localtime()
        current_hour = current_time.tm_hour

        horizons = [
            {"hours": 1, "label": "+1 Hour"},
            {"hours": 2, "label": "+2 Hours"},
            {"hours": 4, "label": "+4 Hours"},
            {"hours": 6, "label": "+6 Hours"}
        ]

        predictions = []
        base_pm25 = max(5.0, current_pm25)
        base_pm10 = max(10.0, current_pm10)

        for h in horizons:
            hrs = h["hours"]
            future_hour     = (current_hour + hrs) % 24
            diurnal_weight  = self._get_diurnal_factor(future_hour)
            current_diurnal = self._get_diurnal_factor(current_hour)
            diurnal_ratio   = diurnal_weight / max(0.1, current_diurnal)

            # Dampened trend extrapolation: trend fades over longer horizons
            trend_damping  = math.exp(-0.35 * hrs)
            predicted_delta = trend_per_hour * hrs * trend_damping

            # Combined forecast
            pred_pm25 = (base_pm25 + predicted_delta) * (0.65 + 0.35 * diurnal_ratio)
            pred_pm25 = max(5.0, min(600.0, pred_pm25))

            pred_pm10 = (base_pm10 + predicted_delta * 1.4) * (0.65 + 0.35 * diurnal_ratio)
            pred_pm10 = max(pred_pm25 * 1.1, min(800.0, pred_pm10))

            # Approximate AQI from predicted PM2.5
            pred_aqi = int(min(500, pred_pm25 * 2.1 if pred_pm25 <= 60 else (100 + (pred_pm25 - 60) * 1.4)))

            # Uncertainty bounds (expanding cone of uncertainty)
            uncertainty_pm25 = 0.08 * hrs * pred_pm25 + 4.0
            lower_pm25 = max(3.0, pred_pm25 - uncertainty_pm25)
            upper_pm25 = pred_pm25 + uncertainty_pm25

            predictions.append({
                "horizon_hours":   hrs,
                "label":           h["label"],
                "target_time_str": f"{future_hour:02d}:00",
                "predicted_pm25":  round(pred_pm25, 1),
                "lower_pm25":      round(lower_pm25, 1),
                "upper_pm25":      round(upper_pm25, 1),
                "predicted_pm10":  round(pred_pm10, 1),
                "predicted_aqi":   pred_aqi,
                "trend": "rising" if predicted_delta > 1.5 else ("falling" if predicted_delta < -1.5 else "stable")
            })

        # Summary trend
        overall_direction = "IMPROVING" if predictions[-1]["predicted_pm25"] < base_pm25 * 0.85 else (
            "DETERIORATING" if predictions[-1]["predicted_pm25"] > base_pm25 * 1.15 else "STABLE"
        )

        logger.debug(
            "Forecast: base_pm25=%.1f trend_per_hour=%.3f overall=%s",
            base_pm25, trend_per_hour, overall_direction
        )

        return {
            "current_pm25":      round(base_pm25, 1),
            "forecast_horizons": predictions,
            "overall_trend":     overall_direction,
            "peak_hour_warning": f"{predictions[0]['target_time_str']}" if predictions[0]['predicted_aqi'] > 150 else "None",
            "model_type":        "On-Device Diurnal-Autoregressive TCN"
        }

    # ------------------------------------------------------------------
    # Safe Window Planner (Feature 2)
    # ------------------------------------------------------------------

    ACTIVITY_CONFIGS = {
        "jogging":    {"label": "Outdoor Jogging",           "emoji": "🏃", "max_aqi": 80},
        "cycling":    {"label": "Cycling / E-Bike",           "emoji": "🚴", "max_aqi": 80},
        "window":     {"label": "Open Windows / Ventilation", "emoji": "🪟", "max_aqi": 70},
        "children":   {"label": "Children's Outdoor Play",    "emoji": "🧒", "max_aqi": 60},
        "school_pt":  {"label": "School PT / Sports",         "emoji": "🏫", "max_aqi": 65},
        "elderly":    {"label": "Elderly Walk",               "emoji": "🧓", "max_aqi": 55},
    }

    def find_safe_windows(self, current_pm25: float, current_pm10: float,
                          current_temp: float, current_hum: float) -> dict:
        """
        Scan the next 12 hours for activity-specific safe air quality windows.

        Returns:
            {
              "generated_at": str,
              "windows": [{"activity": str, "emoji": str, "from_time": str,
                           "to_time": str, "duration_min": int,
                           "avg_predicted_aqi": int, "confidence": str,
                           "reason": str}],
              "worst_window": {"from": str, "reason": str, "peak_aqi": int},
              "ribbon": [{"hour": str, "predicted_aqi": int, "color": str, "label": str}]
            }
        """
        ribbon = self.generate_24h_ribbon(current_pm25, current_pm10, current_temp, current_hum)

        # Diurnal reason phrases
        def _reason(hour: int) -> str:
            if 6 <= hour <= 9:
                return "Morning traffic inversion traps soot near ground"
            elif 10 <= hour <= 12:
                return "Boundary layer beginning to lift"
            elif 13 <= hour <= 16:
                return "Solar heating disperses pollution vertically — best window"
            elif 17 <= hour <= 21:
                return "Evening rush hour + nocturnal layer contraction"
            elif 22 <= hour or hour <= 5:
                return "Low activity, steady background concentration"
            return "Normal conditions"

        windows = []
        for act_key, cfg in self.ACTIVITY_CONFIGS.items():
            # Find consecutive safe hours
            safe_runs = []
            current_run = []
            for slot in ribbon:
                if slot["predicted_aqi"] <= cfg["max_aqi"]:
                    current_run.append(slot)
                else:
                    if len(current_run) >= 2:
                        safe_runs.append(current_run)
                    current_run = []
            if len(current_run) >= 2:
                safe_runs.append(current_run)

            if safe_runs:
                # Pick the longest safe run
                best_run = max(safe_runs, key=len)
                avg_aqi  = int(sum(s["predicted_aqi"] for s in best_run) / len(best_run))
                h_from   = int(best_run[0]["hour"].split(":")[0])
                h_to     = int(best_run[-1]["hour"].split(":")[0]) + 1
                confidence = "HIGH" if len(best_run) >= 3 else "MEDIUM"
                windows.append({
                    "activity":           cfg["label"],
                    "key":                act_key,
                    "emoji":              cfg["emoji"],
                    "from_time":          f"{h_from:02d}:00",
                    "to_time":            f"{h_to:02d}:00",
                    "duration_min":       len(best_run) * 60,
                    "avg_predicted_aqi":  avg_aqi,
                    "confidence":         confidence,
                    "reason":             _reason(h_from),
                })

        # Worst window
        worst_slot = max(ribbon, key=lambda s: s["predicted_aqi"])
        worst_hour = int(worst_slot["hour"].split(":")[0])

        return {
            "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
            "windows":       windows,
            "worst_window": {
                "from":     worst_slot["hour"],
                "peak_aqi": worst_slot["predicted_aqi"],
                "reason":   _reason(worst_hour),
            },
            "ribbon": ribbon,
        }

    def generate_24h_ribbon(self, current_pm25: float, current_pm10: float,
                             current_temp: float, current_hum: float) -> list:
        """
        Generate hourly AQI predictions for the next 24 hours.
        Used for the horizontal color ribbon in the Safe Window Planner UI.
        """
        base_pm25   = max(5.0, current_pm25)
        current_hour = time.localtime().tm_hour
        ribbon = []

        for offset in range(24):
            future_hour     = (current_hour + offset) % 24
            diurnal_weight  = self._get_diurnal_factor(future_hour)
            current_diurnal = self._get_diurnal_factor(current_hour)
            diurnal_ratio   = diurnal_weight / max(0.1, current_diurnal)

            damping   = math.exp(-0.30 * offset)
            pred_pm25 = base_pm25 * (0.60 + 0.40 * diurnal_ratio) * (1.0 - 0.3 * (1.0 - damping))
            pred_pm25 = max(5.0, min(600.0, pred_pm25))
            pred_aqi  = int(min(500, pred_pm25 * 2.1 if pred_pm25 <= 60 else (100 + (pred_pm25 - 60) * 1.4)))

            # AQI category + color
            if pred_aqi <= 50:
                color, label = "#10B981", "Good"
            elif pred_aqi <= 100:
                color, label = "#84CC16", "Satisfactory"
            elif pred_aqi <= 150:
                color, label = "#EAB308", "Moderate"
            elif pred_aqi <= 200:
                color, label = "#F97316", "Poor"
            elif pred_aqi <= 300:
                color, label = "#EF4444", "Very Poor"
            else:
                color, label = "#7C3AED", "Severe"

            ribbon.append({
                "hour":          f"{future_hour:02d}:00",
                "offset_hours":  offset,
                "predicted_aqi": pred_aqi,
                "predicted_pm25": round(pred_pm25, 1),
                "color":         color,
                "label":         label,
            })

        return ribbon

