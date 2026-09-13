"""
feature_pipeline.py
===================
Real-time stoichiometric feature engineering, baseline calibration,
multi-pollutant international AQI calculation (NAQI, US EPA, EU CAQI, WHO 2021),
and universal multi-environment indices (VPD, Cognitive Drowsiness, Infection Risk, OSHA TWA).
Runs locally on Qualcomm QRB2210 Cortex-A53 Linux core.
"""

import logging
import math
import time
from collections import deque
from typing import Dict, Any, List, Optional

__all__ = ["FeaturePipeline"]

logger = logging.getLogger(__name__)


class FeaturePipeline:
    STANDARDS = ["NAQI", "US_EPA", "EU_CAQI", "WHO_2021"]

    DEFAULT_CALIBRATION = {
        "pm1":  {"gain": 1.0, "offset": 0.0, "enabled": True},
        "pm25": {"gain": 1.0, "offset": 0.0, "enabled": True},
        "pm10": {"gain": 1.0, "offset": 0.0, "enabled": True},
        "co2":  {"gain": 1.0, "offset": 0.0, "enabled": True},
        "no2":  {"gain": 1.0, "offset": 0.0, "enabled": True},
        "co":   {"gain": 1.0, "offset": 0.0, "enabled": True},
        "nh3":  {"gain": 1.0, "offset": 0.0, "enabled": True},
        "voc":  {"gain": 1.0, "offset": 0.0, "enabled": True},
        "tmp":  {"gain": 1.0, "offset": 0.0, "enabled": True},
        "hum":  {"gain": 1.0, "offset": 0.0, "enabled": True},
        "prs":  {"gain": 1.0, "offset": 0.0, "enabled": True},
    }

    def __init__(self, history_window_size: int = 30, active_standard: str = "NAQI"):
        self.history_window_size = history_window_size
        self.active_standard = active_standard if active_standard in self.STANDARDS else "NAQI"
        self.calibration = {k: dict(v) for k, v in self.DEFAULT_CALIBRATION.items()}

        # O(1) deques for time-series rates of change
        self.pm25_history: deque = deque(maxlen=history_window_size)
        self.co_history:   deque = deque(maxlen=history_window_size)
        self.no2_history:  deque = deque(maxlen=history_window_size)
        self.voc_history:  deque = deque(maxlen=history_window_size)
        self.timestamps:   deque = deque(maxlen=history_window_size)

    # ------------------------------------------------------------------
    # Configuration: Standards & Calibration
    # ------------------------------------------------------------------

    def set_standard(self, standard_name: str) -> bool:
        if standard_name in self.STANDARDS:
            self.active_standard = standard_name
            logger.info("Active AQI Standard updated to: %s", standard_name)
            return True
        return False

    def update_calibration(self, calib_dict: Dict[str, Dict[str, Any]]):
        for ch, params in calib_dict.items():
            if ch in self.calibration:
                if "gain" in params:
                    self.calibration[ch]["gain"] = float(params["gain"])
                elif "scale" in params:
                    self.calibration[ch]["gain"] = float(params["scale"])
                if "offset" in params:
                    self.calibration[ch]["offset"] = float(params["offset"])
                if "enabled" in params:
                    self.calibration[ch]["enabled"] = bool(params["enabled"])
        logger.info("Sensor calibration updated: %s", self.calibration)

    def apply_calibration(self, channel: str, raw_val: float, min_val: float = 0.0) -> float:
        cfg = self.calibration.get(channel, {"gain": 1.0, "offset": 0.0, "enabled": True})
        if not cfg.get("enabled", True):
            return min_val
        val = raw_val * cfg.get("gain", 1.0) + cfg.get("offset", 0.0)
        return max(min_val, val)

    # ------------------------------------------------------------------
    # Core Breakpoint Linear Interpolator
    # ------------------------------------------------------------------

    def calculate_aqi_sub_index(self, concentration: float, breakpoints: List[tuple], max_scale: float = 500.0) -> float:
        """
        Piecewise linear interpolation:
        breakpoints: [(C_low, C_high, I_low, I_high), ...]
        """
        if concentration <= 0:
            return 0.0
        for c_low, c_high, i_low, i_high in breakpoints:
            if c_low <= concentration <= c_high:
                if c_high == c_low:
                    return float(i_low)
                return ((i_high - i_low) / (c_high - c_low)) * (concentration - c_low) + i_low
        # Exceeds maximum breakpoint
        c_low, c_high, i_low, i_high = breakpoints[-1]
        return min(max_scale, i_high + (concentration - c_high) * 0.5)

    # ------------------------------------------------------------------
    # International Multi-Standard AQI Engine
    # ------------------------------------------------------------------

    def compute_composite_aqi(self, pm25: float, pm10: float, no2: float, co: float, standard: Optional[str] = None) -> Dict[str, Any]:
        """
        Calculates composite AQI based on selected international standard:
        - NAQI: Indian National Air Quality Index (CPCB)
        - US_EPA: United States EPA Revised AQI
        - EU_CAQI: European Common Air Quality Index
        - WHO_2021: World Health Organization Global Air Quality Targets
        """
        std = standard or self.active_standard

        if std == "US_EPA":
            return self._compute_us_epa_aqi(pm25, pm10, no2, co)
        elif std == "EU_CAQI":
            return self._compute_eu_caqi(pm25, pm10, no2, co)
        elif std == "WHO_2021":
            return self._compute_who_aqi(pm25, pm10, no2, co)
        else:
            return self._compute_indian_naqi(pm25, pm10, no2, co)

    def _compute_indian_naqi(self, pm25: float, pm10: float, no2: float, co: float) -> Dict[str, Any]:
        pm25_bp = [
            (0, 30, 0, 50),
            (31, 60, 51, 100),
            (61, 90, 101, 200),
            (91, 120, 201, 300),
            (121, 250, 301, 400),
            (251, 500, 401, 500)
        ]
        pm10_bp = [
            (0, 50, 0, 50),
            (51, 100, 51, 100),
            (101, 250, 101, 200),
            (251, 350, 201, 300),
            (351, 430, 301, 400),
            (431, 600, 401, 500)
        ]
        no2_ugm3 = no2 * 1880.0
        no2_bp = [
            (0, 40, 0, 50),
            (41, 80, 51, 100),
            (81, 180, 101, 200),
            (181, 280, 201, 300),
            (281, 400, 301, 400),
            (401, 1000, 401, 500)
        ]
        co_mgm3 = co * 1.15
        co_bp = [
            (0, 1.0, 0, 50),
            (1.1, 2.0, 51, 100),
            (2.1, 10.0, 101, 200),
            (10.1, 17.0, 201, 300),
            (17.1, 34.0, 301, 400),
            (34.1, 50.0, 401, 500)
        ]

        sub_indices = {
            "PM2.5": round(self.calculate_aqi_sub_index(pm25, pm25_bp), 1),
            "PM10":  round(self.calculate_aqi_sub_index(pm10, pm10_bp), 1),
            "NO2":   round(self.calculate_aqi_sub_index(no2_ugm3, no2_bp), 1),
            "CO":    round(self.calculate_aqi_sub_index(co_mgm3, co_bp), 1)
        }

        primary_pollutant = max(sub_indices, key=sub_indices.get)
        overall_aqi = round(sub_indices[primary_pollutant])

        if overall_aqi <= 50:
            category, color = "Good", "#10B981"
        elif overall_aqi <= 100:
            category, color = "Satisfactory", "#84CC16"
        elif overall_aqi <= 200:
            category, color = "Moderate", "#FBBF24"
        elif overall_aqi <= 300:
            category, color = "Poor", "#F97316"
        elif overall_aqi <= 400:
            category, color = "Very Poor", "#EF4444"
        else:
            category, color = "Severe", "#9333EA"

        return {
            "standard": "NAQI (India CPCB)",
            "aqi": overall_aqi,
            "category": category,
            "color": color,
            "primary_pollutant": primary_pollutant,
            "sub_indices": sub_indices
        }

    def _compute_us_epa_aqi(self, pm25: float, pm10: float, no2: float, co: float) -> Dict[str, Any]:
        """US EPA Air Quality Index standard breakpoints (revised 2024 PM2.5)."""
        pm25_bp = [
            (0.0, 9.0, 0, 50),
            (9.1, 35.4, 51, 100),
            (35.5, 55.4, 101, 150),
            (55.5, 125.4, 151, 200),
            (125.5, 225.4, 201, 300),
            (225.5, 500.0, 301, 500)
        ]
        pm10_bp = [
            (0, 54, 0, 50),
            (55, 154, 51, 100),
            (155, 254, 101, 150),
            (255, 354, 151, 200),
            (355, 424, 201, 300),
            (425, 604, 301, 500)
        ]
        no2_ppb = no2 * 1000.0
        no2_bp = [
            (0, 53, 0, 50),
            (54, 100, 51, 100),
            (101, 360, 101, 150),
            (361, 649, 151, 200),
            (650, 1249, 201, 300),
            (1250, 2049, 301, 500)
        ]
        co_bp = [
            (0.0, 4.4, 0, 50),
            (4.5, 9.4, 51, 100),
            (9.5, 12.4, 101, 150),
            (12.5, 15.4, 151, 200),
            (15.5, 30.4, 201, 300),
            (30.5, 50.0, 301, 500)
        ]

        sub_indices = {
            "PM2.5": round(self.calculate_aqi_sub_index(pm25, pm25_bp), 1),
            "PM10":  round(self.calculate_aqi_sub_index(pm10, pm10_bp), 1),
            "NO2":   round(self.calculate_aqi_sub_index(no2_ppb, no2_bp), 1),
            "CO":    round(self.calculate_aqi_sub_index(co, co_bp), 1)
        }

        primary_pollutant = max(sub_indices, key=sub_indices.get)
        overall_aqi = round(sub_indices[primary_pollutant])

        if overall_aqi <= 50:
            category, color = "Good", "#10B981"
        elif overall_aqi <= 100:
            category, color = "Moderate", "#FBBF24"
        elif overall_aqi <= 150:
            category, color = "Unhealthy for Sensitive Groups", "#F97316"
        elif overall_aqi <= 200:
            category, color = "Unhealthy", "#EF4444"
        elif overall_aqi <= 300:
            category, color = "Very Unhealthy", "#A855F7"
        else:
            category, color = "Hazardous", "#7E22CE"

        return {
            "standard": "US EPA AQI",
            "aqi": overall_aqi,
            "category": category,
            "color": color,
            "primary_pollutant": primary_pollutant,
            "sub_indices": sub_indices
        }

    def _compute_eu_caqi(self, pm25: float, pm10: float, no2: float, co: float) -> Dict[str, Any]:
        """European Common Air Quality Index (0-100 scale)."""
        pm25_bp = [
            (0, 15, 0, 25),
            (16, 30, 26, 50),
            (31, 55, 51, 75),
            (56, 110, 76, 100)
        ]
        pm10_bp = [
            (0, 25, 0, 25),
            (26, 50, 26, 50),
            (51, 90, 51, 75),
            (91, 180, 76, 100)
        ]
        no2_ugm3 = no2 * 1880.0
        no2_bp = [
            (0, 50, 0, 25),
            (51, 100, 26, 50),
            (101, 200, 51, 75),
            (201, 400, 76, 100)
        ]
        co_mgm3 = co * 1.15
        co_bp = [
            (0, 5.0, 0, 25),
            (5.1, 7.5, 26, 50),
            (7.6, 10.0, 51, 75),
            (10.1, 20.0, 76, 100)
        ]

        sub_indices = {
            "PM2.5": round(self.calculate_aqi_sub_index(pm25, pm25_bp, max_scale=150.0), 1),
            "PM10":  round(self.calculate_aqi_sub_index(pm10, pm10_bp, max_scale=150.0), 1),
            "NO2":   round(self.calculate_aqi_sub_index(no2_ugm3, no2_bp, max_scale=150.0), 1),
            "CO":    round(self.calculate_aqi_sub_index(co_mgm3, co_bp, max_scale=150.0), 1)
        }

        primary_pollutant = max(sub_indices, key=sub_indices.get)
        overall_aqi = round(sub_indices[primary_pollutant])

        if overall_aqi <= 25:
            category, color = "Very Low", "#10B981"
        elif overall_aqi <= 50:
            category, color = "Low", "#84CC16"
        elif overall_aqi <= 75:
            category, color = "Medium", "#FBBF24"
        elif overall_aqi <= 100:
            category, color = "High", "#F97316"
        else:
            category, color = "Very High", "#EF4444"

        return {
            "standard": "European CAQI",
            "aqi": overall_aqi,
            "category": category,
            "color": color,
            "primary_pollutant": primary_pollutant,
            "sub_indices": sub_indices
        }

    def _compute_who_aqi(self, pm25: float, pm10: float, no2: float, co: float) -> Dict[str, Any]:
        """WHO 2021 Global Air Quality Guidelines."""
        no2_ugm3 = no2 * 1880.0
        co_mgm3 = co * 1.15

        r_pm25 = (pm25 / 15.0) * 50.0
        r_pm10 = (pm10 / 45.0) * 50.0
        r_no2  = (no2_ugm3 / 25.0) * 50.0
        r_co   = (co_mgm3 / 4.0) * 50.0

        sub_indices = {
            "PM2.5": round(min(500.0, r_pm25), 1),
            "PM10":  round(min(500.0, r_pm10), 1),
            "NO2":   round(min(500.0, r_no2), 1),
            "CO":    round(min(500.0, r_co), 1)
        }

        primary_pollutant = max(sub_indices, key=sub_indices.get)
        overall_aqi = round(sub_indices[primary_pollutant])

        if overall_aqi <= 50:
            category, color = "WHO Compliant (Optimal)", "#10B981"
        elif overall_aqi <= 100:
            category, color = "Interim Target 4 (Mild Risk)", "#84CC16"
        elif overall_aqi <= 150:
            category, color = "Interim Target 3 (Moderate)", "#FBBF24"
        elif overall_aqi <= 200:
            category, color = "Interim Target 2 (High Risk)", "#F97316"
        else:
            category, color = "Critical Non-Compliance", "#EF4444"

        return {
            "standard": "WHO 2021 Guidelines",
            "aqi": overall_aqi,
            "category": category,
            "color": color,
            "primary_pollutant": primary_pollutant,
            "sub_indices": sub_indices
        }

    # ------------------------------------------------------------------
    # Universal Multi-Environment Specialized Domain Indices
    # ------------------------------------------------------------------

    @staticmethod
    def compute_vpd(temp: float, hum: float) -> Dict[str, Any]:
        """Vapor Pressure Deficit (VPD) in kPa for Greenhouses & Hydroponics."""
        vp_sat = 0.61078 * math.exp((17.27 * temp) / (temp + 237.3))
        vp_act = vp_sat * (hum / 100.0)
        vpd = max(0.0, vp_sat - vp_act)

        if vpd < 0.4:
            status = "Low Transpiration (Fungal Risk)"
            color = "#38BDF8"
        elif vpd <= 1.4:
            status = "Optimal Plant Transpiration"
            color = "#10B981"
        elif vpd <= 1.8:
            status = "High Transpiration (Water Stress)"
            color = "#F59E0B"
        else:
            status = "Critical Stomatal Closure"
            color = "#EF4444"

        return {
            "vpd_kpa": round(vpd, 2),
            "vp_sat_kpa": round(vp_sat, 2),
            "status": status,
            "color": color
        }

    @staticmethod
    def compute_cognitive_drowsiness_index(co2: float, voc: float) -> Dict[str, Any]:
        """Cognitive Drowsiness & Stuffiness Index for Classrooms & Offices."""
        co2_factor = min(100.0, max(0.0, (co2 - 450.0) / (2000.0 - 450.0) * 100.0))
        voc_factor = min(100.0, max(0.0, (voc - 50.0) / (300.0 - 50.0) * 100.0))
        cdi = round(co2_factor * 0.75 + voc_factor * 0.25)

        if cdi < 30:
            status = "Optimal Focus & Alertness"
            color = "#10B981"
        elif cdi < 55:
            status = "Mild Drowsiness / Reduced Focus"
            color = "#FBBF24"
        elif cdi < 80:
            status = "Moderate Cognitive Fatigue"
            color = "#F97316"
        else:
            status = "Severe Drowsiness (Ventilate Now)"
            color = "#EF4444"

        return {
            "cdi_score": cdi,
            "status": status,
            "color": color,
            "ventilation_recommended": cdi >= 50
        }

    @staticmethod
    def compute_infection_risk_index(co2: float, hum: float, pm25: float) -> Dict[str, Any]:
        """Aerosol & Infection Transmission Risk Index for Hospitals & Clinics."""
        exhaled_fraction = min(1.0, max(0.0, (co2 - 420.0) / 980.0))

        if 40.0 <= hum <= 60.0:
            rh_penalty = 0.2
        elif 30.0 <= hum < 40.0 or 60.0 < hum <= 70.0:
            rh_penalty = 0.5
        else:
            rh_penalty = 0.9

        pm_load = min(1.0, pm25 / 50.0)
        raw_score = (exhaled_fraction * 0.50 + rh_penalty * 0.30 + pm_load * 0.20) * 100.0
        score = round(min(100.0, max(5.0, raw_score)))

        if score < 30:
            status = "Low Airborne Risk"
            color = "#10B981"
        elif score < 60:
            status = "Moderate Aerosol Accumulation"
            color = "#FBBF24"
        elif score < 85:
            status = "Elevated Infection Risk"
            color = "#F97316"
        else:
            status = "High Airborne Transmission Risk"
            color = "#EF4444"

        return {
            "infection_risk_score": score,
            "status": status,
            "color": color,
            "sterilization_needed": score >= 60
        }

    @staticmethod
    def compute_osha_twa_indices(no2: float, co: float, voc: float) -> Dict[str, Any]:
        """Occupational Safety (OSHA / NIOSH PEL/TWA) Index for Industrial Plants."""
        no2_pct = round((no2 / 1.0) * 100.0, 1)  # NIOSH 1 ppm
        co_pct  = round((co / 35.0) * 100.0, 1)  # NIOSH 35 ppm
        voc_pct = round((voc / 200.0) * 100.0, 1)

        max_pct = max(no2_pct, co_pct, voc_pct)
        if max_pct < 50.0:
            status = "Within Safe Industrial Baseline"
            color = "#10B981"
        elif max_pct < 100.0:
            status = "Approaching Occupational Limit"
            color = "#FBBF24"
        else:
            status = "Exceeds Occupational Health Limit"
            color = "#EF4444"

        return {
            "max_exposure_pct": round(max_pct, 1),
            "no2_pct_of_limit": no2_pct,
            "co_pct_of_limit": co_pct,
            "voc_pct_of_limit": voc_pct,
            "status": status,
            "color": color
        }

    # ------------------------------------------------------------------
    # Multi-Modal Acoustic & Optical Sensing
    # ------------------------------------------------------------------

    @staticmethod
    def compute_acoustic_spectrum(raw_telemetry: Dict[str, Any]) -> Dict[str, Any]:
        """
        16-band Audio FFT Spectral Power Distribution (31 Hz to 12.5 kHz).
        Fingerprints acoustic resonance for source fusion:
        - Low-band (60-250 Hz): Vehicle engine rumble & diesel vibration
        - Mid-band (500-1600 Hz): Factory machinery, compressors, industrial hum
        - High-band (2-4 kHz): Culinary oil sizzling, frying, turbulent exhaust
        """
        # Center frequencies for 16 standard 1/3-octave bands (Hz)
        center_freqs = [31, 63, 125, 250, 500, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 6300, 8000, 12500]
        
        # Check if hardware DMA I2S mic provided raw 16-band energy
        raw_bands = raw_telemetry.get("acoustic_bands")
        acoustic_rms = float(raw_telemetry.get("acoustic", 0.15))
        voc = float(raw_telemetry.get("voc", 35.0))
        no2 = float(raw_telemetry.get("no2", 0.02))

        if isinstance(raw_bands, list) and len(raw_bands) == 16:
            bands = [min(1.0, max(0.0, float(b))) for b in raw_bands]
        else:
            # Deterministic spectrum synthesis based on physical acoustic excitation
            bands = []
            for idx, f in enumerate(center_freqs):
                if 60 <= f <= 250:
                    # Vehicle rumble excitation correlates with NO2 and acoustic level
                    val = 0.15 + (no2 / 0.08) * 0.55 * min(1.0, acoustic_rms * 1.5)
                elif 500 <= f <= 1600:
                    # Industrial hum excitation
                    val = 0.10 + min(0.60, acoustic_rms * 0.70)
                elif 2000 <= f <= 4000:
                    # Kitchen frying / sizzle excitation correlates with VOC and thermal fan
                    val = 0.08 + (voc / 250.0) * 0.65 * min(1.0, acoustic_rms * 1.2)
                else:
                    val = 0.05 + acoustic_rms * 0.20
                bands.append(round(min(1.0, max(0.02, val)), 3))

        # Band aggregations
        low_energy  = round(sum(bands[1:4]) / 3.0, 3)     # 63, 125, 250 Hz
        mid_energy  = round(sum(bands[4:9]) / 5.0, 3)     # 500 - 1600 Hz
        high_energy = round(sum(bands[9:13]) / 4.0, 3)    # 2000 - 4000 Hz

        # Spectral Centroid (Hz)
        weighted_sum = sum(b * f for b, f in zip(bands, center_freqs))
        total_energy = max(0.001, sum(bands))
        spectral_centroid = round(weighted_sum / total_energy, 1)

        if low_energy > 0.45 and low_energy > high_energy:
            dominant_signature = "Vehicular Traffic Rumble"
            color = "#F97316"
        elif high_energy > 0.45 and high_energy > low_energy:
            dominant_signature = "Culinary Frying Sizzle"
            color = "#8B5CF6"
        elif mid_energy > 0.40:
            dominant_signature = "Industrial Machine Hum"
            color = "#EAB308"
        else:
            dominant_signature = "Normal Ambient Baseline"
            color = "#10B981"

        return {
            "bands": bands,
            "center_freqs": center_freqs,
            "low_band_energy": low_energy,
            "mid_band_energy": mid_energy,
            "high_band_energy": high_energy,
            "spectral_centroid_hz": spectral_centroid,
            "dominant_signature": dominant_signature,
            "color": color,
            "rms_level": round(acoustic_rms, 3)
        }

    @staticmethod
    def compute_optical_haze(pm25: float, pm10: float, hum: float, raw_ambient_lux: float = 500.0) -> Dict[str, Any]:
        """
        Koschmieder atmospheric extinction coefficient and optical haze attenuation.
        Estimates visual contrast attenuation and Aerosol Optical Depth (AOD) surrogate.
        """
        # Hygroscopic particle growth factor f(RH)
        rh_clamped = min(98.0, max(10.0, hum))
        f_rh = 1.0 + 0.25 * math.pow(rh_clamped / (100.1 - rh_clamped), 0.5)

        # Extinction coefficient beta_ext (1/km)
        fine_ext = 3.0 * (pm25 / 100.0) * f_rh
        coarse_ext = 0.6 * (max(0.0, pm10 - pm25) / 100.0)
        beta_ext = max(0.015, fine_ext + coarse_ext + 0.01)

        # Koschmieder meteorological visual range: V_R = 3.912 / beta_ext (km)
        visual_range_km = round(min(50.0, 3.912 / beta_ext), 1)

        # Atmospheric Contrast Attenuation (0 to 100%)
        contrast_attenuation = round(min(100.0, (beta_ext / (beta_ext + 0.20)) * 100.0), 1)

        # AOD surrogate (scale 0.0 to 2.0+)
        aod_surrogate = round(min(2.5, beta_ext * 0.8), 2)

        if visual_range_km >= 20.0:
            haze_status = "Pristine Atmospheric Clarity"
            color = "#10B981"
        elif visual_range_km >= 10.0:
            haze_status = "Light Atmospheric Haze"
            color = "#FBBF24"
        elif visual_range_km >= 4.0:
            haze_status = "Moderate Particulate Smog"
            color = "#F97316"
        else:
            haze_status = "Severe Dense Obscuration"
            color = "#EF4444"

        return {
            "visual_range_km": visual_range_km,
            "extinction_coeff_km": round(beta_ext, 3),
            "contrast_attenuation_pct": contrast_attenuation,
            "aod_surrogate": aod_surrogate,
            "haze_status": haze_status,
            "color": color
        }

    # ------------------------------------------------------------------
    # Feature Extraction with Calibration and Ratios
    # ------------------------------------------------------------------

    def extract_features(self, raw_telemetry: Dict[str, Any]) -> Dict[str, Any]:
        """Extracts stoichiometric features, applies calibration, computes multi-environment indices."""
        pm1  = self.apply_calibration("pm1",  float(raw_telemetry.get("pm1", 10.0)),  min_val=0.1)
        pm25 = self.apply_calibration("pm25", float(raw_telemetry.get("pm25", 15.0)), min_val=0.1)
        pm10 = self.apply_calibration("pm10", float(raw_telemetry.get("pm10", 25.0)), min_val=pm25)
        co2  = self.apply_calibration("co2",  float(raw_telemetry.get("co2", 420.0)), min_val=350.0)
        no2  = self.apply_calibration("no2",  float(raw_telemetry.get("no2", 0.02)),  min_val=0.001)
        co   = self.apply_calibration("co",   float(raw_telemetry.get("co", 0.5)),    min_val=0.01)
        nh3  = self.apply_calibration("nh3",  float(raw_telemetry.get("nh3", 0.5)),   min_val=0.01)
        voc  = self.apply_calibration("voc",  float(raw_telemetry.get("voc", 35.0)),  min_val=1.0)
        temp = self.apply_calibration("tmp",  float(raw_telemetry.get("tmp", 26.0)),  min_val=-20.0)
        hum  = self.apply_calibration("hum",  float(raw_telemetry.get("hum", 55.0)),  min_val=5.0)
        hum  = min(100.0, hum)
        prs  = self.apply_calibration("prs",  float(raw_telemetry.get("prs", 1013.25)), min_val=800.0)

        # 1. Size Fractionation Ratio (0.0 to 1.0)
        pm_ratio = pm25 / pm10

        # 2. Combustion Inefficiency Ratio
        co_to_co2_ratio = (co * 1000.0) / co2

        # 3. Traffic Vehicle Signature Ratio
        no2_to_voc_ratio = (no2 * 1000.0) / voc

        # 4. History Tracking for Rates of Change
        ts = raw_telemetry.get("timestamp", time.time())
        self.pm25_history.append(pm25)
        self.co_history.append(co)
        self.no2_history.append(no2)
        self.voc_history.append(voc)
        self.timestamps.append(ts)

        window = min(10, len(self.pm25_history))
        pm25_list = list(self.pm25_history)
        voc_list  = list(self.voc_history)
        if window > 1:
            d_pm25_dt = (pm25_list[-1] - pm25_list[-window]) / float(window)
            d_voc_dt  = (voc_list[-1]  - voc_list[-window])  / float(window)
        else:
            d_pm25_dt = 0.0
            d_voc_dt = 0.0

        # 5. Atmospheric Inversion Risk
        inversion_risk = 1.0 if (temp < 18.0 and hum > 75.0) else 0.0

        # 6. Selected International AQI Calculation
        aqi_info = self.compute_composite_aqi(pm25, pm10, no2, co)

        # 7. Specialized Environment Domain Indices
        vpd_info = self.compute_vpd(temp, hum)
        cdi_info = self.compute_cognitive_drowsiness_index(co2, voc)
        infection_info = self.compute_infection_risk_index(co2, hum, pm25)
        osha_info = self.compute_osha_twa_indices(no2, co, voc)

        # 8. Multi-Modal Acoustic & Optical Sensing
        acoustic_info = self.compute_acoustic_spectrum(raw_telemetry)
        optical_info = self.compute_optical_haze(pm25, pm10, hum, float(raw_telemetry.get("lux", 500.0)))

        return {
            "timestamp": ts,
            "pm1":  round(pm1, 1),
            "pm25": round(pm25, 1),
            "pm10": round(pm10, 1),
            "co2":  round(co2, 1),
            "no2":  round(no2, 3),
            "co":   round(co, 2),
            "nh3":  round(nh3, 2),
            "voc":  round(voc, 1),
            "tmp":  round(temp, 2),
            "hum":  round(hum, 1),
            "prs":  round(prs, 1),
            "bat":  int(raw_telemetry.get("bat", 100)),
            "vin":  float(raw_telemetry.get("vin", 3.30)),
            # Engineered Features
            "pm_ratio":         round(pm_ratio, 3),
            "co_to_co2_ratio":  round(co_to_co2_ratio, 3),
            "no2_to_voc_ratio": round(no2_to_voc_ratio, 3),
            "d_pm25_dt":        round(d_pm25_dt, 3),
            "d_voc_dt":         round(d_voc_dt, 3),
            "inversion_risk":   inversion_risk,
            # AQI details
            "standard":         aqi_info["standard"],
            "aqi":              aqi_info["aqi"],
            "aqi_category":     aqi_info["category"],
            "aqi_color":        aqi_info["color"],
            "primary_pollutant":aqi_info["primary_pollutant"],
            "sub_indices":      aqi_info["sub_indices"],
            # Specialized Domain Indices
            "vpd":              vpd_info,
            "vpd_kpa":          vpd_info["vpd_kpa"],
            "cdi":              cdi_info,
            "cdi_score":        cdi_info["cdi_score"],
            "infection_risk":   infection_info,
            "infection_risk_score": infection_info["infection_risk_score"],
            "osha_twa":         osha_info,
            "max_exposure_pct": osha_info["max_exposure_pct"],
            # Multi-Modal Sensing
            "acoustic_spectrum": acoustic_info,
            "acoustic_dominant": acoustic_info["dominant_signature"],
            "optical_haze":     optical_info,
            "visual_range_km":  optical_info["visual_range_km"]
        }
