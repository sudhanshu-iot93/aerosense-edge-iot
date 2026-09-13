"""
test_universal_features.py
==========================
Unit tests for universal deployment features:
- International AQI Standards (NAQI, US EPA, EU CAQI, WHO 2021)
- Sensor Calibration Pipeline & Modular Channel Toggles
- Universal Domain Indices (VPD, CDI, Infection Risk, OSHA TWA)
- 8-Environment Profile Advisory Engine
- Smart Automation Rules & Relay Triggering
- Persistent Storage Configuration & Compliance Audit Summaries
"""

import os
import sys
import tempfile
import time
import pytest

sys.path.extend([
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "edge_ai")),
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "edge_core"))
])

from feature_pipeline import FeaturePipeline
from advisory_engine  import AdvisoryEngine
from rules_engine     import RulesEngine
from storage_engine   import EdgeStorageEngine


def test_international_standards():
    fp = FeaturePipeline()

    # 1. Indian NAQI
    naqi = fp.compute_composite_aqi(pm25=25.0, pm10=40.0, no2=0.015, co=0.4, standard="NAQI")
    assert naqi["standard"] == "NAQI (India CPCB)"
    assert naqi["category"] == "Good"
    assert naqi["aqi"] <= 50

    # 2. US EPA AQI
    us_epa = fp.compute_composite_aqi(pm25=25.0, pm10=40.0, no2=0.015, co=0.4, standard="US_EPA")
    assert us_epa["standard"] == "US EPA AQI"
    assert us_epa["category"] == "Moderate"
    assert 51 <= us_epa["aqi"] <= 100

    # 3. EU CAQI
    caqi = fp.compute_composite_aqi(pm25=12.0, pm10=20.0, no2=0.02, co=0.5, standard="EU_CAQI")
    assert caqi["standard"] == "European CAQI"
    assert caqi["category"] in ["Very Low", "Low"]

    # 4. WHO 2021 Guidelines
    who = fp.compute_composite_aqi(pm25=30.0, pm10=60.0, no2=0.025, co=0.8, standard="WHO_2021")
    assert who["standard"] == "WHO 2021 Guidelines"
    assert who["aqi"] >= 50


def test_sensor_calibration_and_channels():
    fp = FeaturePipeline()

    fp.update_calibration({
        "pm25": {"gain": 1.5, "offset": 5.0, "enabled": True}
    })
    calibrated = fp.apply_calibration("pm25", 20.0)
    assert calibrated == 35.0

    fp.update_calibration({
        "pm25": {"gain": 1.0, "offset": 0.0, "enabled": False}
    })
    disabled_val = fp.apply_calibration("pm25", 20.0, min_val=0.1)
    assert disabled_val == 0.1


def test_universal_domain_indices():
    # 1. Vapor Pressure Deficit (VPD)
    vpd_opt = FeaturePipeline.compute_vpd(temp=25.0, hum=60.0)
    assert 0.8 <= vpd_opt["vpd_kpa"] <= 1.5
    assert "Optimal" in vpd_opt["status"]

    vpd_stress = FeaturePipeline.compute_vpd(temp=35.0, hum=20.0)
    assert vpd_stress["vpd_kpa"] > 2.0

    # 2. Cognitive Drowsiness Index (CDI)
    cdi_low = FeaturePipeline.compute_cognitive_drowsiness_index(co2=450.0, voc=25.0)
    assert cdi_low["cdi_score"] < 25
    assert not cdi_low["ventilation_recommended"]

    cdi_high = FeaturePipeline.compute_cognitive_drowsiness_index(co2=1600.0, voc=180.0)
    assert cdi_high["cdi_score"] > 60
    assert cdi_high["ventilation_recommended"]

    # 3. Infection Risk Index
    inf_low = FeaturePipeline.compute_infection_risk_index(co2=450.0, hum=50.0, pm25=10.0)
    assert inf_low["infection_risk_score"] < 35

    inf_high = FeaturePipeline.compute_infection_risk_index(co2=1500.0, hum=15.0, pm25=60.0)
    assert inf_high["infection_risk_score"] > 65
    assert inf_high["sterilization_needed"]

    # 4. OSHA Industrial Exposure Index
    osha_safe = FeaturePipeline.compute_osha_twa_indices(no2=0.02, co=1.0, voc=30.0)
    assert osha_safe["max_exposure_pct"] < 50.0


def test_advisory_engine_profiles():
    adv = AdvisoryEngine()
    telemetry = {
        "aqi": 85,
        "pm25": 28.0,
        "pm10": 45.0,
        "co2": 1150.0,
        "no2": 0.03,
        "co": 0.8,
        "voc": 40.0,
        "tmp": 24.0,
        "hum": 55.0,
        "vpd": {"vpd_kpa": 1.1},
        "cdi": {"cdi_score": 52},
        "infection_risk": {"infection_risk_score": 35},
        "osha_twa": {"max_exposure_pct": 25.0}
    }
    source_info = {"primary_source": "Clean Baseline", "confidence_percent": 88}
    forecast_info = {"overall_trend": "STABLE"}

    for profile in AdvisoryEngine.PROFILES:
        res = adv.generate_advisory(telemetry, source_info, forecast_info, profile=profile)
        assert res["profile"] is not None
        assert "headline" in res
        assert len(res["citizen_actions"]) > 0
        assert len(res["school_actions"]) > 0
        assert len(res["community_actions"]) > 0


def test_rules_engine_automation():
    re = RulesEngine()
    re.load_profile_rules("Kitchen")

    telemetry = {"voc": 220.0, "co": 1.2, "aqi": 80}
    source = {"primary_source": "Cooking Smoke"}

    re.evaluate(telemetry, source)
    assert re.relays[1]["state"] is True

    telemetry_clean = {"voc": 30.0, "co": 0.3, "aqi": 30}
    source_clean = {"primary_source": "Clean Baseline"}
    re.evaluate(telemetry_clean, source_clean)
    assert re.relays[1]["state"] is False


def test_storage_engine_config_and_audit():
    temp_dir = tempfile.mkdtemp()
    db_path = os.path.join(temp_dir, "test_audit.db")

    storage = EdgeStorageEngine(db_path=db_path)

    # 1. Config Persistence
    storage.set_config("active_profile", "Hospital")
    assert storage.get_config("active_profile") == "Hospital"

    # 2. Logging and Compliance Audit with current timestamp
    now = time.time()
    storage.log_telemetry(
        features={"timestamp": now, "pm1": 8, "pm25": 12.0, "pm10": 20.0, "co2": 420,
                  "no2": 0.015, "co": 0.4, "nh3": 0.2, "voc": 25, "tmp": 24, "hum": 50,
                  "prs": 1013, "aqi": 40, "bat": 98},
        source_attribution={"primary_source": "Clean Baseline", "confidence_percent": 95}
    )

    audit = storage.get_compliance_audit_summary(hours=24)
    assert audit["total_samples"] >= 1
    assert audit["compliance_pct_who"] == 100.0
    assert audit["air_quality_status"] == "Compliant"
