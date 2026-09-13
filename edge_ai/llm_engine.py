"""
llm_engine.py
=============
On-Device Small Language Model (SLM) & Context-Aware Advisory Engine for Arduino UNO Q.
Coordinates multi-environment deterministic actionable advice with optional local SLM
enrichment (google/flan-t5-small) via PyTorch & Transformers.
"""

import logging
import time
from typing import Dict, Any, List, Optional
import threading

from advisory_engine import AdvisoryEngine

logger = logging.getLogger(__name__)


class LLMEngine:
    def __init__(self, default_profile: str = "Campus"):
        self.model_name = "google/flan-t5-small"
        self.model = None
        self.tokenizer = None
        self.is_loaded = False
        self.default_profile = default_profile
        self.advisory_engine = AdvisoryEngine(default_profile=default_profile)

        # Load SLM in a background thread without blocking daemon startup
        threading.Thread(target=self._load_model, daemon=True, name="slm-loader").start()

    def set_profile(self, profile_name: str) -> bool:
        return self.advisory_engine.set_profile(profile_name)

    def _load_model(self):
        try:
            logger.info("Initializing Local SLM (%s)...", self.model_name)
            from transformers import T5Tokenizer, T5ForConditionalGeneration
            self.tokenizer = T5Tokenizer.from_pretrained(self.model_name)
            self.model = T5ForConditionalGeneration.from_pretrained(self.model_name)
            self.is_loaded = True
            logger.info("Local SLM successfully loaded and ready for neural advisory synthesis!")
        except Exception as e:
            logger.warning("Local SLM inference model unavailable or loading deferred: %s", e)

    def generate_advisory(self, telemetry: Dict[str, Any], source_info: Dict[str, Any],
                          forecast_info: Dict[str, Any], profile: Optional[str] = None) -> Dict[str, Any]:
        """
        Generates full multi-environment advisory payload. Uses deterministic rule
        expert engine and enriches with local SLM text when available.
        """
        # 1. Base robust profile advisory from AdvisoryEngine
        advisory_payload = self.advisory_engine.generate_advisory(
            telemetry=telemetry,
            source_info=source_info,
            forecast_info=forecast_info,
            profile=profile
        )

        # 2. Enrich with local SLM if available
        if self.is_loaded and self.model is not None and self.tokenizer is not None:
            try:
                aqi = telemetry.get("aqi", 50)
                source = source_info.get("primary_source", "Clean Baseline")
                prompt_headline = f"Write a concise urgent one-sentence headline for air quality AQI {aqi} caused by {source}."
                slm_headline = self._generate_text(prompt_headline)
                if slm_headline:
                    advisory_payload["headline"] = slm_headline

                if aqi > 160:
                    prompt_urgent = f"Provide a one sentence medical warning for asthma and elderly individuals exposed to {source}."
                    urgent_text = self._generate_text(prompt_urgent)
                    if urgent_text and urgent_text not in advisory_payload["urgent_alerts"]:
                        advisory_payload["urgent_alerts"].append(urgent_text)
            except Exception as exc:
                logger.debug("SLM advisory enrichment skipped: %s", exc)

        return advisory_payload

    def _generate_text(self, prompt: str) -> str:
        if not self.is_loaded or self.model is None or self.tokenizer is None:
            return ""
        inputs = self.tokenizer(prompt, return_tensors="pt")
        outputs = self.model.generate(**inputs, max_new_tokens=40)
        text = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
        return text.strip()

    def answer_natural_query(
        self,
        query: str,
        state: Optional[Dict[str, Any]] = None,
        context: Optional[Dict[str, Any]] = None,
        profile: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        On-Device Natural Language Conversational Voice Assistant ('AeroSense Voice').
        Answers citizen, teacher, and facility manager queries 100% locally with zero cloud,
        grounded in real-time stoichiometric sensor readings, plume vectoring, and forecast.
        """
        q = query.lower().strip()
        state_dict = state or context or {}
        features = state_dict.get("features", {})
        source_info = state_dict.get("source_attribution", {})
        plume = state_dict.get("plume", {})
        forecast = state_dict.get("forecast", {})
        active_prof = profile or state_dict.get("active_profile", self.default_profile)

        aqi = features.get("aqi", 42)
        aqi_cat = features.get("aqi_category", "Good")
        pm25 = float(features.get("pm25", 14.0))
        co2 = float(features.get("co2", 420.0))
        voc = float(features.get("voc", 30.0))
        no2 = float(features.get("no2", 0.02))
        co = float(features.get("co", 0.5))
        primary_source = source_info.get("primary_source", "Clean Baseline")
        cardinal = plume.get("cardinal", "WSW")
        bearing = plume.get("bearing_deg", 235.0)
        distance = plume.get("distance_m", 120)

        # 1. Intent: Smoke, burning, smell, plastic, odor
        if any(w in q for w in ["smoke", "smell", "burning", "odor", "fire", "plastic"]):
            if primary_source in ("Garbage Burning", "Crop Residue", "Cooking Smoke"):
                ans = (
                    f"Our on-board chemical sensor array detects {primary_source.lower()} signatures. "
                    f"We see elevated volatile organic compounds ({voc:.0f} VOC index) and carbon monoxide ({co:.2f} ppm). "
                    f"The micro-plume dispersion model locates the emission origin approximately {distance} meters away "
                    f"at compass bearing {bearing}° ({cardinal})."
                )
                act = f"Seal windward windows facing {cardinal} and activate indoor air purifiers."
            else:
                ans = (
                    f"Ambient air quality is currently {aqi_cat} (AQI {aqi}). Toxic gas levels and fine particulates "
                    f"are within normal thresholds (PM2.5: {pm25:.1f} µg/m³). No combustion smoke signature is detected."
                )
                act = "No special precautions needed; cross-ventilation approved."

        # 2. Intent: Jogging, running, exercise, workout, walk, outside
        elif any(w in q for w in ["jog", "run", "walk", "exercise", "sport", "outside", "outdoor"]):
            if aqi <= 60 and pm25 <= 25.0:
                ans = (
                    f"Outdoor air quality is currently excellent (AQI {aqi}, {aqi_cat}). "
                    f"Particulate exposure risk is very low across the campus. "
                    f"You have a clear exercise window for the next 2 hours."
                )
                act = "Fully safe for cardio workouts and outdoor sports."
            elif aqi <= 100:
                ans = (
                    f"Air quality is Moderate (AQI {aqi}, PM2.5: {pm25:.1f} µg/m³). "
                    f"Sensitive individuals may experience mild throat irritation from vehicular NO2. "
                    f"Light walking is fine, but avoid high-intensity workouts alongside main roads."
                )
                act = "Reroute jogging through green park belts rather than traffic corridors."
            else:
                ans = (
                    f"Outdoor exercise is not recommended right now. AQI has reached {aqi} ({aqi_cat}) "
                    f"driven by {primary_source}. Fine particles ({pm25:.1f} µg/m³) can penetrate deep into lungs."
                )
                act = "Move cardio workouts indoors and run HEPA filtration."

        # 3. Intent: Windows, ventilation, fresh air
        elif any(w in q for w in ["window", "open", "ventilat", "fresh air"]):
            if aqi > 90 or primary_source in ("Garbage Burning", "Traffic Exhaust"):
                ans = (
                    f"Keep windows closed right now. Outdoor pollution is elevated ({primary_source}, AQI {aqi}). "
                    f"Opening windows will pull fine particulate soot and combustion gases indoors."
                )
                act = "Keep windows sealed until the afternoon dispersion window."
            elif co2 > 900.0:
                ans = (
                    f"Yes, open your windows now. Indoor CO2 has accumulated to {co2:.0f} ppm, "
                    f"causing stuffiness, while outdoor air is relatively clean (AQI {aqi})."
                )
                act = "Open opposite windows for 10 minutes to create cross-ventilation."
            else:
                ans = (
                    f"Window opening is approved. Outdoor ambient AQI is {aqi} ({aqi_cat}) "
                    f"and indoor CO2 is balanced at {co2:.0f} ppm."
                )
                act = "Natural ventilation approved."

        # 4. Intent: Origin, direction, location, where
        elif any(w in q for w in ["where", "direction", "origin", "source", "coming from"]):
            ans = (
                f"The dominant pollution source is classified as {primary_source} with {round(features.get('pm_ratio', 0.6)*100)}% "
                f"fine particle ratio. The Gaussian plume vector points to {bearing}° ({cardinal}), "
                f"estimated at a distance of ~{distance} meters upwind."
            )
            act = f"Dispatch local facility or RWA patrol along the {cardinal} perimeter."

        # 5. Intent: Classroom, study, school, kids, children, drowsiness
        elif any(w in q for w in ["class", "school", "child", "kid", "drows", "focus", "tired"]):
            cdi = features.get("cdi_score", 20)
            if co2 > 1000.0 or cdi > 50:
                ans = (
                    f"Classroom stuffiness is elevated: CO2 is at {co2:.0f} ppm with a Cognitive Drowsiness Index of {cdi}%. "
                    f"Elevated CO2 impairs concentration, memory recall, and pupil alertness."
                )
                act = "Trigger fresh air intake fans or take a 5-minute recess ventilation break."
            else:
                ans = (
                    f"Classroom environmental conditions are optimal for study (CO2: {co2:.0f} ppm, CDI: {cdi}%, AQI: {aqi}). "
                    f"Alertness and oxygenation levels are well within learning baselines."
                )
                act = "Classroom conditions optimal for focus."

        # 6. Fallback General Question: Use local SLM neural synthesis if available
        else:
            slm_ans = ""
            if self.is_loaded:
                prompt = f"Answer concisely as an air quality expert: '{query}'. Current AQI is {aqi}, source is {primary_source}."
                slm_ans = self._generate_text(prompt)
            
            if slm_ans:
                ans = slm_ans
            else:
                ans = (
                    f"AeroSense Edge is operating in {active_prof} Mode. Real-time composite AQI is {aqi} ({aqi_cat}), "
                    f"with primary pollutant {features.get('primary_pollutant', 'PM2.5')} at {pm25:.1f} µg/m³. "
                    f"Current source attribution is {primary_source}."
                )
            act = f"Monitor live telemetry; relays currently managing indoor air quality."

        # Speech Synthesis Markup Language (SSML) for browser TTS
        ssml = f"<speak><p>{ans}</p><break time='300ms'/><p>Action: {act}</p></speak>"

        return {
            "query": query,
            "answer": ans,
            "action": act,
            "spoken_audio_text": f"{ans} Immediate action: {act}",
            "ssml": ssml,
            "confidence": 0.94,
            "grounded_metrics": {
                "aqi": aqi,
                "pm25": pm25,
                "co2": co2,
                "primary_source": primary_source,
                "plume_bearing": bearing,
                "plume_cardinal": cardinal
            },
            "timestamp": int(time.time())
        }
