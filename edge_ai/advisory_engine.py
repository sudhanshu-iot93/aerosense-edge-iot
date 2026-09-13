"""
advisory_engine.py
==================
Context-Aware Actionable Advisory Engine for Arduino UNO Q.
Translates raw AQI numbers, AI source attributions, and domain indices into concrete,
plain-language daily actions tailored to 8 Anywhere Deployment Profiles:
  1. Campus / Smart City (Citizen, School, Municipal/RWA)
  2. Classroom / Educational (Teachers, Facilities, Students)
  3. Hospital / Healthcare (Infection Control, Ward Nurse, HVAC Facility)
  4. Industrial / Manufacturing (Safety Officer, Operators, Facility Tech)
  5. Commercial Kitchen / Restaurant (Head Chef, Staff, Hood Ventilation)
  6. Smart Greenhouse / Agriculture (Grower, Irrigation/Misting, Climate)
  7. Transit Hub / Metro Station (Station Master, Commuters, Jet Fans)
  8. Residential / Smart Home (Homeowner, Sensitive Members, Purifiers)

Operates 100% offline on-device with zero cloud API dependency.
"""

import logging
from typing import Dict, Any, List, Optional

__all__ = ["AdvisoryEngine"]

logger = logging.getLogger(__name__)


class AdvisoryEngine:
    PROFILES = [
        "Campus",
        "Classroom",
        "Hospital",
        "Industrial",
        "Kitchen",
        "Greenhouse",
        "Transit",
        "Residential"
    ]

    def __init__(self, default_profile: str = "Campus"):
        self.active_profile = default_profile if default_profile in self.PROFILES else "Campus"

    def set_profile(self, profile_name: str) -> bool:
        if profile_name in self.PROFILES:
            self.active_profile = profile_name
            logger.info("Advisory profile set to: %s", profile_name)
            return True
        return False

    def generate_advisory(self, telemetry: Dict[str, Any], source_info: Dict[str, Any],
                          forecast_info: Dict[str, Any], profile: Optional[str] = None) -> Dict[str, Any]:
        """
        Synthesizes multi-sensor readings, source attribution, domain indices,
        and 6-hour forecast into targeted actionable advice for the active profile.
        """
        prof          = profile or self.active_profile
        aqi           = telemetry.get("aqi", 50)
        source        = source_info.get("primary_source", "Clean Baseline")
        confidence    = source_info.get("confidence_percent", 80)
        forecast_trend = forecast_info.get("overall_trend", "STABLE")

        # Routing to profile-specific advisory generators
        if prof == "Classroom":
            return self._generate_classroom_advisory(telemetry, source, confidence, forecast_trend)
        elif prof == "Hospital":
            return self._generate_hospital_advisory(telemetry, source, confidence, forecast_trend)
        elif prof == "Industrial":
            return self._generate_industrial_advisory(telemetry, source, confidence, forecast_trend)
        elif prof == "Kitchen":
            return self._generate_kitchen_advisory(telemetry, source, confidence, forecast_trend)
        elif prof == "Greenhouse":
            return self._generate_greenhouse_advisory(telemetry, source, confidence, forecast_trend)
        elif prof == "Transit":
            return self._generate_transit_advisory(telemetry, source, confidence, forecast_trend)
        elif prof == "Residential":
            return self._generate_residential_advisory(telemetry, source, confidence, forecast_trend)
        else:
            return self._generate_campus_advisory(telemetry, source, confidence, forecast_trend)

    # ------------------------------------------------------------------
    # 1. Campus / Smart City Advisory
    # ------------------------------------------------------------------
    def _generate_campus_advisory(self, t: Dict[str, Any], source: str, conf: int, trend: str) -> Dict[str, Any]:
        aqi = t.get("aqi", 50)
        citizen_actions = []
        school_actions  = []
        community_actions = []
        urgent_alerts   = []

        if aqi <= 50:
            headline = f"Air Quality is pristine (AQI {aqi}). Open windows and enjoy outdoor recreation."
            citizen_actions.append({"action": "Open windows for cross-ventilation", "timing": "All Day", "icon": "wind", "priority": "LOW"})
            citizen_actions.append({"action": "Outdoor cardio & jogging safe", "timing": "Unrestricted", "icon": "running", "priority": "LOW"})
            school_actions.append({"action": "Conduct outdoor physical education", "timing": "All sessions", "icon": "futbol", "priority": "LOW"})
            community_actions.append({"action": "Clean baseline maintained; no active enforcement", "timing": "Normal", "icon": "check-circle", "priority": "LOW"})
        elif aqi <= 100:
            headline = f"Moderate air quality (AQI {aqi}). Sensitive groups should limit strenuous outdoor cardio."
            citizen_actions.append({"action": "Ventilate indoor spaces during mid-day hours", "timing": "12:00 - 15:00", "icon": "door-open", "priority": "LOW"})
            citizen_actions.append({"action": "Sensitive individuals reduce intense outdoor cardio", "timing": "Morning rush", "icon": "heart-pulse", "priority": "MEDIUM"})
            school_actions.append({"action": "Allow normal outdoor recess for healthy students", "timing": "Recess", "icon": "school", "priority": "LOW"})
            community_actions.append({"action": "Monitor construction dust and traffic corridors", "timing": "Routine", "icon": "shield", "priority": "LOW"})
        elif aqi <= 200:
            headline = f"Poor air quality (AQI {aqi}) due to {source}. Morning inversion trapping particulates."
            citizen_actions.append({"action": "Wear N95 mask if commuting along arterial roads", "timing": "During commute", "icon": "head-side-mask", "priority": "HIGH"})
            citizen_actions.append({"action": "Keep roadside windows closed", "timing": "07:00 - 10:30", "icon": "shield", "priority": "HIGH"})
            school_actions.append({"action": "Shift morning sports indoors to gymnasium", "timing": "07:00 - 11:00", "icon": "volleyball", "priority": "HIGH"})
            community_actions.append({"action": "Deploy water mist cannons on unpaved roads", "timing": "Immediate", "icon": "faucet-drip", "priority": "HIGH"})
        else:
            headline = f"CRITICAL AIR QUALITY (AQI {aqi})! Severe {source} pollution detected."
            urgent_alerts.append(f"HAZARDOUS SMOKE PLUME ({aqi} AQI): High exposure risk from {source}!")
            citizen_actions.append({"action": "Mandatory N95/FFP2 respirator mask outdoors", "timing": "Always outdoors", "icon": "head-side-mask", "priority": "CRITICAL"})
            citizen_actions.append({"action": "Seal windows and run HEPA air cleaners", "timing": "Continuous", "icon": "fan", "priority": "CRITICAL"})
            school_actions.append({"action": "Cancel outdoor activities; seal classroom windows", "timing": "Immediate", "icon": "ban", "priority": "CRITICAL"})
            community_actions.append({"action": "Dispatch patrol to extinguish open burning source", "timing": "Immediate", "icon": "truck-fast", "priority": "CRITICAL"})

        return {
            "profile": "Campus / Smart City",
            "headline": headline,
            "overall_aqi": aqi,
            "source_attributed": source,
            "confidence_percent": conf,
            "optimal_window": "14:00 - 16:00",
            "avoid_window": "07:00 - 09:30",
            "urgent_alerts": urgent_alerts,
            "citizen_actions": citizen_actions,
            "school_actions": school_actions,
            "community_actions": community_actions
        }

    # ------------------------------------------------------------------
    # 2. Classroom / Educational Advisory
    # ------------------------------------------------------------------
    def _generate_classroom_advisory(self, t: Dict[str, Any], source: str, conf: int, trend: str) -> Dict[str, Any]:
        aqi = t.get("aqi", 50)
        co2 = t.get("co2", 420.0)
        cdi = t.get("cdi", {}).get("cdi_score", 15)
        urgent_alerts = []
        teacher_actions = []
        facility_actions = []
        student_actions = []

        if co2 > 1200:
            headline = f"Classroom CO2 is elevated ({int(co2)} ppm). Cognitive focus declining (CDI {cdi})."
            urgent_alerts.append(f"CLASSROOM VENTILATION ALERT: CO2 at {int(co2)} ppm causing student drowsiness!")
            teacher_actions.append({"action": "Open classroom door and cross-corridor windows for 5 minutes", "timing": "Immediately between lectures", "icon": "door-open", "priority": "HIGH"})
            facility_actions.append({"action": "Switch HVAC to 100% outside air fresh intake cycle", "timing": "Immediate", "icon": "fan", "priority": "HIGH"})
            student_actions.append({"action": "Take a 2-minute stretch break; drink water", "timing": "Now", "icon": "glass-water", "priority": "MEDIUM"})
        elif co2 > 800:
            headline = f"Classroom air is satisfactory (CO2 {int(co2)} ppm). Schedule routine air flush."
            teacher_actions.append({"action": "Crack upper window transom slightly for steady airflow", "timing": "During class", "icon": "wind", "priority": "LOW"})
            facility_actions.append({"action": "Maintain normal 25% fresh air intake rate", "timing": "Normal", "icon": "sliders", "priority": "LOW"})
            student_actions.append({"action": "Learning conditions optimal for concentration", "timing": "All day", "icon": "book-open", "priority": "LOW"})
        else:
            headline = f"Excellent learning environment (CO2 {int(co2)} ppm, AQI {aqi}). Peak cognitive alertness."
            teacher_actions.append({"action": "Air quality optimal for high-focus testing or lectures", "timing": "Current Session", "icon": "brain", "priority": "LOW"})
            facility_actions.append({"action": "Filters operating with high efficiency", "timing": "Routine check", "icon": "check", "priority": "LOW"})
            student_actions.append({"action": "Peak mental focus supported by clean fresh air", "timing": "Full Day", "icon": "award", "priority": "LOW"})

        return {
            "profile": "Classroom / Educational",
            "headline": headline,
            "overall_aqi": aqi,
            "source_attributed": source,
            "confidence_percent": conf,
            "optimal_window": "Recess Air Flush (10:30 & 13:00)",
            "avoid_window": "Late Afternoon Closed Stuffy (14:30 - 16:00)",
            "urgent_alerts": urgent_alerts,
            "citizen_actions": teacher_actions,     # Maps to primary role
            "school_actions": facility_actions,      # Maps to facility role
            "community_actions": student_actions     # Maps to student role
        }

    # ------------------------------------------------------------------
    # 3. Hospital / Healthcare Advisory
    # ------------------------------------------------------------------
    def _generate_hospital_advisory(self, t: Dict[str, Any], source: str, conf: int, trend: str) -> Dict[str, Any]:
        aqi = t.get("aqi", 50)
        pm25 = t.get("pm25", 15.0)
        risk = t.get("infection_risk", {}).get("infection_risk_score", 20)
        urgent_alerts = []
        infection_actions = []
        ward_actions = []
        facility_actions = []

        if pm25 > 25 or risk > 60:
            headline = f"Hospital Cleanliness Alert: Aerosol risk index {risk}/100. PM2.5 elevated at {pm25} µg/m³."
            urgent_alerts.append(f"ICU/WARD INFECTION CONTROL: Aerosol transmission risk score {risk} exceeds safe threshold!")
            infection_actions.append({"action": "Mandate N95 respirator masks in respiratory & ICU wards", "timing": "Continuous", "icon": "head-side-mask", "priority": "CRITICAL"})
            ward_actions.append({"action": "Ensure patient isolation room negative pressure differential", "timing": "Verify Hourly", "icon": "shield-virus", "priority": "HIGH"})
            facility_actions.append({"action": "Run terminal HEPA filters at maximum air change rate (12 ACH)", "timing": "Immediate", "icon": "fan", "priority": "CRITICAL"})
        else:
            headline = f"Hospital sterility baseline secure. Low infection risk ({risk}/100), PM2.5 {pm25} µg/m³."
            infection_actions.append({"action": "Maintain standard universal precautions", "timing": "Routine", "icon": "user-nurse", "priority": "LOW"})
            ward_actions.append({"action": "Patient room air exchanges within WHO sterile limits", "timing": "Continuous", "icon": "bed-pulse", "priority": "LOW"})
            facility_actions.append({"action": "UV-C germicidal and HEPA filtration operating normally", "timing": "Nominal", "icon": "circle-check", "priority": "LOW"})

        return {
            "profile": "Hospital / Healthcare",
            "headline": headline,
            "overall_aqi": aqi,
            "source_attributed": source,
            "confidence_percent": conf,
            "optimal_window": "Sterilization Window (11:00 - 13:00)",
            "avoid_window": "Shift Change Aerosol Peak (07:00 - 08:30)",
            "urgent_alerts": urgent_alerts,
            "citizen_actions": infection_actions,
            "school_actions": ward_actions,
            "community_actions": facility_actions
        }

    # ------------------------------------------------------------------
    # 4. Industrial / Manufacturing Advisory
    # ------------------------------------------------------------------
    def _generate_industrial_advisory(self, t: Dict[str, Any], source: str, conf: int, trend: str) -> Dict[str, Any]:
        aqi = t.get("aqi", 50)
        osha = t.get("osha_twa", {})
        max_pct = osha.get("max_exposure_pct", 20.0)
        no2 = t.get("no2", 0.02)
        co  = t.get("co", 0.5)
        urgent_alerts = []
        safety_actions = []
        operator_actions = []
        hvac_actions = []

        if max_pct >= 80.0 or aqi > 180:
            headline = f"INDUSTRIAL SAFETY WARNING: Exposure at {max_pct}% of OSHA/NIOSH limit! ({source})"
            urgent_alerts.append(f"TOXIC GAS ALERT: Workshop gases at {max_pct}% of legal occupational limit!")
            safety_actions.append({"action": "Evacuate non-essential personnel from welding/coating line", "timing": "Immediate", "icon": "triangle-exclamation", "priority": "CRITICAL"})
            operator_actions.append({"action": "Don supplied-air or dual-cartridge organic vapor respirators", "timing": "Mandatory", "icon": "head-side-mask", "priority": "CRITICAL"})
            hvac_actions.append({"action": "Actuate emergency industrial extraction dampers & roof exhausters", "timing": "Automated Triggered", "icon": "wind", "priority": "CRITICAL"})
        else:
            headline = f"Plant floor within OSHA safe threshold ({max_pct}% of allowable TWA). NO2 {no2} ppm."
            safety_actions.append({"action": "Log 8-hour shift time-weighted exposure baseline", "timing": "End of shift", "icon": "clipboard-check", "priority": "LOW"})
            operator_actions.append({"action": "Standard eye protection and task-specific dust mask", "timing": "Normal shift", "icon": "glasses", "priority": "LOW"})
            hvac_actions.append({"action": "Local capture hoods operating at nominal capture velocity", "timing": "Nominal", "icon": "fan", "priority": "LOW"})

        return {
            "profile": "Industrial / Workshop",
            "headline": headline,
            "overall_aqi": aqi,
            "source_attributed": source,
            "confidence_percent": conf,
            "optimal_window": "Exhaust Purge Cycle (12:30 - 13:30)",
            "avoid_window": "Peak Production Overlap (09:00 - 11:30)",
            "urgent_alerts": urgent_alerts,
            "citizen_actions": safety_actions,
            "school_actions": operator_actions,
            "community_actions": hvac_actions
        }

    # ------------------------------------------------------------------
    # 5. Commercial Kitchen / Restaurant Advisory
    # ------------------------------------------------------------------
    def _generate_kitchen_advisory(self, t: Dict[str, Any], source: str, conf: int, trend: str) -> Dict[str, Any]:
        aqi = t.get("aqi", 50)
        voc = t.get("voc", 35.0)
        co  = t.get("co", 0.5)
        urgent_alerts = []
        chef_actions = []
        staff_actions = []
        relay_actions = []

        if voc > 180 or co > 3.0 or source == "Cooking Smoke":
            headline = f"Commercial Kitchen Alert: Oil aerosol & VOC spike ({int(voc)} VOC). Exhaust Hood relay engaged."
            if co > 5.0:
                urgent_alerts.append(f"CARBON MONOXIDE RISK: Gas burner incomplete combustion detected ({co} ppm)!")
            chef_actions.append({"action": "Cover hot frying vats; reduce burner flame flare-up", "timing": "Immediate", "icon": "fire-burner", "priority": "HIGH"})
            staff_actions.append({"action": "Open back dock delivery ventilation door", "timing": "Now", "icon": "door-open", "priority": "HIGH"})
            relay_actions.append({"action": "Smart Range Hood Relay automatically actuated at 100% capacity", "timing": "Active Relay #1", "icon": "fan", "priority": "CRITICAL"})
        else:
            headline = f"Kitchen air quality clear (VOC {int(voc)}, CO {co} ppm). Hood operating on eco-mode."
            chef_actions.append({"action": "Normal prep cooking with standard range hood speed", "timing": "Shift", "icon": "utensils", "priority": "LOW"})
            staff_actions.append({"action": "Check grease baffle filter cleanliness", "timing": "Daily closing", "icon": "filter", "priority": "LOW"})
            relay_actions.append({"action": "Relay #1 idle; monitoring combustion gases", "timing": "Standby", "icon": "toggle-on", "priority": "LOW"})

        return {
            "profile": "Commercial Kitchen",
            "headline": headline,
            "overall_aqi": aqi,
            "source_attributed": source,
            "confidence_percent": conf,
            "optimal_window": "Mid-afternoon Prep (14:30 - 17:00)",
            "avoid_window": "Dinner Rush Peak (19:00 - 21:30)",
            "urgent_alerts": urgent_alerts,
            "citizen_actions": chef_actions,
            "school_actions": staff_actions,
            "community_actions": relay_actions
        }

    # ------------------------------------------------------------------
    # 6. Smart Greenhouse / Agriculture Advisory
    # ------------------------------------------------------------------
    def _generate_greenhouse_advisory(self, t: Dict[str, Any], source: str, conf: int, trend: str) -> Dict[str, Any]:
        aqi = t.get("aqi", 50)
        vpd_info = t.get("vpd", {})
        vpd = vpd_info.get("vpd_kpa", 1.0)
        co2 = t.get("co2", 420.0)
        urgent_alerts = []
        grower_actions = []
        misting_actions = []
        enrich_actions = []

        if vpd < 0.5:
            headline = f"Greenhouse VPD is LOW ({vpd} kPa). High mold/fungal risk! Transpiration stalled."
            urgent_alerts.append(f"VPD DEPRESSION ({vpd} kPa): Dehumidify and open ridge vents to prevent botrytis rot!")
            grower_actions.append({"action": "Open greenhouse roof vents and activate horizontal air circulation (HAF) fans", "timing": "Immediate", "icon": "fan", "priority": "HIGH"})
            misting_actions.append({"action": "Disable high-pressure misting sprinklers", "timing": "Override OFF", "icon": "circle-stop", "priority": "HIGH"})
            enrich_actions.append({"action": "Suspend liquid CO2 dosing until humidity drops below 75%", "timing": "Hold", "icon": "flask", "priority": "MEDIUM"})
        elif vpd > 1.5:
            headline = f"Greenhouse VPD is HIGH ({vpd} kPa). Plants experiencing stomatal closure & water stress!"
            urgent_alerts.append(f"WATER STRESS WARNING: VPD {vpd} kPa causing leaf scorch and growth stoppage!")
            grower_actions.append({"action": "Deploy thermal shade screens to reduce canopy solar heat load", "timing": "Immediate", "icon": "sun", "priority": "HIGH"})
            misting_actions.append({"action": "Trigger high-pressure fogging mist relay for 45 seconds", "timing": "Actuate Relay #2", "icon": "cloud-rain", "priority": "HIGH"})
            enrich_actions.append({"action": "Maintain soil root-zone drip fertigation cycle", "timing": "Boost cycle", "icon": "faucet", "priority": "MEDIUM"})
        else:
            headline = f"Optimal Microclimate! VPD {vpd} kPa, CO2 {int(co2)} ppm. Peak vegetative photosynthesis."
            grower_actions.append({"action": "Canopy transpiration rate is in the biological sweet-spot (0.8 - 1.2 kPa)", "timing": "Optimal", "icon": "seedling", "priority": "LOW"})
            misting_actions.append({"action": "Microclimate stability target maintained", "timing": "Nominal", "icon": "check", "priority": "LOW"})
            enrich_actions.append({"action": "Maintain target CO2 enrichment at 800-1000 ppm during solar hours", "timing": "10:00 - 15:00", "icon": "leaf", "priority": "LOW"})

        return {
            "profile": "Smart Greenhouse / Ag",
            "headline": headline,
            "overall_aqi": aqi,
            "source_attributed": source,
            "confidence_percent": conf,
            "optimal_window": "Peak Solar Enrichment (10:30 - 14:00)",
            "avoid_window": "Late Dusk Condensation Window (17:30 - 19:00)",
            "urgent_alerts": urgent_alerts,
            "citizen_actions": grower_actions,
            "school_actions": misting_actions,
            "community_actions": enrich_actions
        }

    # ------------------------------------------------------------------
    # 7. Transit Hub / Metro Subway Advisory
    # ------------------------------------------------------------------
    def _generate_transit_advisory(self, t: Dict[str, Any], source: str, conf: int, trend: str) -> Dict[str, Any]:
        aqi = t.get("aqi", 50)
        pm10 = t.get("pm10", 25.0)
        no2 = t.get("no2", 0.02)
        urgent_alerts = []
        station_actions = []
        commuter_actions = []
        fan_actions = []

        if pm10 > 150 or no2 > 0.06:
            headline = f"Transit Hub Bottleneck: Heavy brake dust & diesel particulate (PM10 {pm10} µg/m³)."
            urgent_alerts.append(f"SUBWAY PLATFORM SMOG: Particulate levels elevated from train braking friction!")
            station_actions.append({"action": "Activate platform screen door overpressure air curtain", "timing": "Rush Hour", "icon": "train", "priority": "HIGH"})
            commuter_actions.append({"action": "Wear protective face mask on underground platform", "timing": "While waiting", "icon": "head-side-mask", "priority": "HIGH"})
            fan_actions.append({"action": "Ramp tunnel axial jet fans to 100% scavenge speed", "timing": "Actuate Relay #1", "icon": "fan", "priority": "CRITICAL"})
        else:
            headline = f"Platform ventilation clear (PM10 {pm10} µg/m³, AQI {aqi}). Passenger airflow optimal."
            station_actions.append({"action": "Maintain standard scheduled ventilation sweeps", "timing": "Nominal", "icon": "building", "priority": "LOW"})
            commuter_actions.append({"action": "Air quality safe for comfortable transit", "timing": "Normal", "icon": "person-walking", "priority": "LOW"})
            fan_actions.append({"action": "Tunnel ventilation on energy-efficient base velocity", "timing": "Eco Mode", "icon": "leaf", "priority": "LOW"})

        return {
            "profile": "Transit Hub / Metro",
            "headline": headline,
            "overall_aqi": aqi,
            "source_attributed": source,
            "confidence_percent": conf,
            "optimal_window": "Mid-Day Transit Valley (11:30 - 15:30)",
            "avoid_window": "Morning Commuter Rush (08:00 - 09:45)",
            "urgent_alerts": urgent_alerts,
            "citizen_actions": station_actions,
            "school_actions": commuter_actions,
            "community_actions": fan_actions
        }

    # ------------------------------------------------------------------
    # 8. Residential / Smart Home Advisory
    # ------------------------------------------------------------------
    def _generate_residential_advisory(self, t: Dict[str, Any], source: str, conf: int, trend: str) -> Dict[str, Any]:
        aqi = t.get("aqi", 50)
        pm25 = t.get("pm25", 15.0)
        voc = t.get("voc", 35.0)
        urgent_alerts = []
        home_actions = []
        purifier_actions = []
        sleep_actions = []

        if aqi > 100 or pm25 > 35:
            headline = f"Indoor Home Air is degraded (AQI {aqi}, PM2.5 {pm25} µg/m³). Purifier boost recommended."
            if source == "Garbage Burning" or source == "Traffic Exhaust":
                urgent_alerts.append(f"OUTDOOR PLUME DETECTED: Keep windows shut; {source} detected in vicinity!")
            home_actions.append({"action": "Keep windows closed until outdoor ambient cleans up", "timing": "Until afternoon", "icon": "door-closed", "priority": "HIGH"})
            purifier_actions.append({"action": "Run HEPA air purifier on High / Turbo mode", "timing": "Continuous", "icon": "fan", "priority": "HIGH"})
            sleep_actions.append({"action": "Turn on bedroom air cleaner 30 mins before bedtime", "timing": "Bedtime prep", "icon": "moon", "priority": "MEDIUM"})
        else:
            headline = f"Home air quality is fresh & healthy (AQI {aqi}). Ideal indoor sanctuary."
            home_actions.append({"action": "Open windows for morning fresh air replacement", "timing": "06:30 - 08:30", "icon": "wind", "priority": "LOW"})
            purifier_actions.append({"action": "Purifiers can operate on ultra-quiet whisper sleep mode", "timing": "Nominal", "icon": "volume-low", "priority": "LOW"})
            sleep_actions.append({"action": "Air conditions optimal for restorative deep sleep", "timing": "Overnight", "icon": "bed", "priority": "LOW"})

        return {
            "profile": "Residential / Home",
            "headline": headline,
            "overall_aqi": aqi,
            "source_attributed": source,
            "confidence_percent": conf,
            "optimal_window": "Morning Fresh Air Window (06:30 - 08:30)",
            "avoid_window": "Late Night Road Inversion (23:00 - 04:00)",
            "urgent_alerts": urgent_alerts,
            "citizen_actions": home_actions,
            "school_actions": purifier_actions,
            "community_actions": sleep_actions
        }

    # ------------------------------------------------------------------
    # Smart Daily Briefing Generator (Feature 5)
    # ------------------------------------------------------------------

    _RISK_LEVELS = [
        (50,  "LOW",      "✅"),
        (100, "MODERATE", "🟡"),
        (150, "ELEVATED", "🟠"),
        (200, "HIGH",     "🔴"),
        (300, "SEVERE",   "⚠️"),
        (999, "HAZARDOUS","🚨"),
    ]

    def generate_daily_briefing(
        self,
        current_telemetry: dict,
        source_info: dict,
        forecast_info: dict,
        health_exposure: dict,
        profile: str = "Campus",
        briefing_type: str = "MORNING"   # "MORNING" or "EVENING"
    ) -> dict:
        """
        Generate a smart AI daily air quality briefing.

        Args:
            current_telemetry:  Latest features dict (pm25, aqi, co2, etc.)
            source_info:        Latest source attribution dict
            forecast_info:      Latest forecast dict
            health_exposure:    Today's cumulative health exposure dict
            profile:            Active deployment profile
            briefing_type:      "MORNING" or "EVENING"

        Returns:
            {
              "type": str, "headline": str, "briefing_text": str,
              "key_actions": [str], "risk_level": str, "risk_emoji": str,
              "community_alert": str | None, "generated_at": str
            }
        """
        import time as _time

        aqi    = current_telemetry.get("aqi", 50)
        pm25   = current_telemetry.get("pm25", 15.0)
        co2    = current_telemetry.get("co2", 420.0)
        source = source_info.get("primary_source", "Clean Baseline")
        trend  = forecast_info.get("overall_trend", "STABLE")
        cig    = health_exposure.get("cigarette_equivalent", 0.0)
        comp   = health_exposure.get("who_compliance_pct", 100.0)

        # Determine risk level
        risk_label, risk_emoji = "LOW", "✅"
        for threshold, label, emoji in self._RISK_LEVELS:
            if aqi <= threshold:
                risk_label, risk_emoji = label, emoji
                break

        # Forecast context
        forecast_horizons = forecast_info.get("forecast_horizons", [])
        next_hour_aqi = forecast_horizons[0]["predicted_aqi"] if forecast_horizons else aqi

        trend_phrase = {
            "IMPROVING":    "Air quality is expected to improve through the day.",
            "STABLE":       "Conditions are expected to remain stable.",
            "DETERIORATING":"Conditions may worsen — take precautions early.",
        }.get(trend, "Conditions are expected to remain stable.")

        if briefing_type == "MORNING":
            headline, briefing, actions = self._morning_briefing(
                aqi, pm25, co2, source, trend_phrase, risk_label, next_hour_aqi, profile
            )
        else:
            headline, briefing, actions = self._evening_briefing(
                aqi, cig, comp, source, trend_phrase, risk_label, profile
            )

        # Community alert (only for high-severity sources)
        community_alert = None
        if source in ("Garbage Burning", "Crop Residue") and aqi > 150:
            community_alert = (
                f"🚨 {source} detected with AQI {aqi}. "
                f"RWA/Municipal teams should locate and address the source immediately."
            )

        return {
            "type":              briefing_type,
            "headline":          headline,
            "briefing_text":     briefing,
            "key_actions":       actions,
            "risk_level":        risk_label,
            "risk_emoji":        risk_emoji,
            "current_aqi":       aqi,
            "current_source":    source,
            "forecast_trend":    trend,
            "community_alert":   community_alert,
            "generated_at":      _time.strftime("%Y-%m-%dT%H:%M:%S"),
            "profile":           profile,
        }

    def _morning_briefing(self, aqi, pm25, co2, source, trend_phrase, risk, next_aqi, profile):
        if aqi <= 50:
            headline = f"Good morning! Excellent air quality — AQI {aqi}. Perfect conditions for outdoor activity."
            briefing = (
                f"Air quality is pristine this morning at AQI {aqi} (PM2.5: {pm25:.1f} µg/m³). "
                f"Today is an excellent day for outdoor sports, open-window ventilation, and school recess. "
                f"{trend_phrase}"
            )
            actions = [
                "🏃 Ideal conditions for outdoor jogging and sports all morning",
                "🪟 Open windows for maximum natural cross-ventilation",
                "🏫 Outdoor school recess and PT fully approved — no restrictions",
                "🌿 Great day to air out indoor spaces and mattresses",
            ]
        elif aqi <= 100:
            headline = f"Good morning. Moderate air quality (AQI {aqi}). Outdoor activities are safe for most people."
            briefing = (
                f"Morning air quality is satisfactory at AQI {aqi} (PM2.5: {pm25:.1f} µg/m³, source: {source}). "
                f"Most outdoor activities are safe. Sensitive groups (children, elderly, asthma) should consider "
                f"limiting prolonged exertion. {trend_phrase}"
            )
            actions = [
                "🏃 Outdoor exercise is safe for healthy adults — limit duration to <60 min",
                "🧒 Children: moderate outdoor play is fine; avoid heavy exertion",
                "🪟 Open windows for ventilation during cooler morning hours",
                f"📊 Monitor AQI — next hour forecast: {next_aqi}",
            ]
        elif aqi <= 200:
            headline = f"⚠️ Caution: AQI {aqi} ({source}). Limit outdoor exposure this morning."
            briefing = (
                f"Air quality is {risk} this morning (AQI {aqi}, PM2.5: {pm25:.1f} µg/m³). "
                f"Primary source identified: {source}. Avoid prolonged outdoor activities, especially "
                f"for children, elderly, and those with respiratory conditions. {trend_phrase}"
            )
            actions = [
                "😷 Wear N95 mask for any outdoor travel",
                "🏫 Move school morning assembly and PT indoors",
                "🪟 Keep windows closed; run air purifiers on maximum",
                "🚫 Cancel or postpone outdoor sports events",
            ]
        else:
            headline = f"🚨 URGENT: Hazardous AQI {aqi} ({source}). Stay indoors immediately."
            briefing = (
                f"HAZARDOUS conditions this morning (AQI {aqi}, PM2.5: {pm25:.1f} µg/m³). "
                f"Source: {source}. All outdoor activities must be suspended. Seal all windows and doors. "
                f"Run HEPA air purifiers at maximum. {trend_phrase}"
            )
            actions = [
                "🚨 All outdoor activities SUSPENDED — stay indoors",
                "🪟 Seal all windows, doors, and ventilation openings",
                "💨 Run HEPA air purifiers at maximum speed continuously",
                "🏥 Sensitive individuals: contact medical help if breathing difficulty occurs",
            ]
        return headline, briefing, actions

    def _evening_briefing(self, aqi, cig, comp, source, trend_phrase, risk, profile):
        cig_str  = f"{cig:.1f}" if cig >= 0.1 else "<0.1"
        headline = (
            f"Evening Summary: AQI {aqi} · WHO compliance: {comp:.0f}% · "
            f"~{cig_str} cigarette equivalent today"
        )
        briefing = (
            f"Today's air quality summary: Current AQI {aqi} ({source}). "
            f"WHO 24h PM2.5 compliance for today was {comp:.0f}%. "
            f"Total PM2.5 exposure equivalent to approximately {cig_str} cigarettes. "
            f"{trend_phrase} Overnight air quality is expected to be relatively stable."
        )
        if comp >= 80:
            actions = [
                "✅ Great air quality day! Open windows for overnight ventilation",
                "😴 Safe to sleep with windows slightly open",
                "🌿 Tomorrow looks equally promising — plan outdoor activities",
            ]
        else:
            actions = [
                "😴 Keep bedroom windows closed tonight; run purifier on sleep mode",
                "💧 Stay hydrated — PM2.5 exposure can dry respiratory membranes",
                "🌅 Check tomorrow morning's briefing before outdoor activities",
            ]
        return headline, briefing, actions
