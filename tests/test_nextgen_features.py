"""
test_nextgen_features.py
========================
Verification suite for Category-Defining Next-Gen Edge AI features on Arduino UNO Q:
 1. 16-Band Acoustic Audio-FFT Spectrum & Koschmieder Optical Extinction Haze
 2. Hyperlocal Micro-Atmospheric Gaussian Plume Dispersion & Origin Vectoring
 3. Model Predictive Control (MPC) Lookahead Preemptive Automation
 4. Grounded On-Device Offline Conversational Voice Assistant ("AeroSense Voice")
 5. Tamper-Proof Cryptographic SHA-256 Merkle Audit Ledger & Regulatory Certificate
"""

import os
import sys
import pytest

sys.path.extend([
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..")),
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "edge_ai")),
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "edge_core"))
])

from edge_ai.feature_pipeline import FeaturePipeline
from edge_ai.source_classifier import SourceClassifier
from edge_ai.plume_vectoring import MicroPlumeVectorEngine
from edge_ai.llm_engine import LLMEngine
from edge_core.rules_engine import RulesEngine
from edge_core.storage_engine import EdgeStorageEngine


# ---------------------------------------------------------------------------
# 1. Acoustic Audio-FFT & Optical Haze Sensor Fusion Tests
# ---------------------------------------------------------------------------

def test_acoustic_spectrum_and_optical_haze():
    pipeline = FeaturePipeline(active_standard="NAQI")
    raw = {
        "pm25": 78.5,
        "pm10": 142.0,
        "co2": 620.0,
        "co": 2.8,
        "no2": 0.045,
        "voc": 110.0,
        "tmp": 29.5,
        "hum": 72.0,
        "lux": 1500.0,
        "acoustic": 68.5,
        "acoustic_low": 42.0,
        "acoustic_mid": 18.0,
        "acoustic_high": 8.5
    }
    feats = pipeline.extract_features(raw)

    # 1a. Acoustic Spectrum
    assert "acoustic_spectrum" in feats
    spec = feats["acoustic_spectrum"]
    assert "bands" in spec
    assert len(spec["bands"]) == 16
    assert "center_freqs" in spec
    assert len(spec["center_freqs"]) == 16
    assert "low_band_energy" in spec
    assert "mid_band_energy" in spec
    assert "high_band_energy" in spec
    assert "spectral_centroid_hz" in spec
    assert "dominant_signature" in spec

    # 1b. Optical Haze
    assert "optical_haze" in feats
    haze = feats["optical_haze"]
    assert "extinction_coeff_km" in haze
    assert haze["extinction_coeff_km"] > 0
    assert "visual_range_km" in haze
    assert haze["visual_range_km"] < 50.0
    assert "contrast_attenuation_pct" in haze
    assert 0 <= haze["contrast_attenuation_pct"] <= 100
    assert "haze_status" in haze


def test_source_classifier_multimodal_acoustic_fusion():
    pipeline = FeaturePipeline(active_standard="NAQI")
    classifier = SourceClassifier()

    # High low-frequency acoustic energy + elevated NO2 + PM2.5 = Traffic Exhaust
    raw = {
        "pm25": 65.0,
        "pm10": 110.0,
        "co": 3.2,
        "no2": 0.065,
        "voc": 140.0,
        "co2": 520.0,
        "tmp": 31.0,
        "hum": 60.0,
        "acoustic": 64.0,
        "acoustic_low": 48.0,
        "acoustic_mid": 12.0,
        "acoustic_high": 4.0
    }
    feats = pipeline.extract_features(raw)
    res = classifier.classify(feats, acoustic_traffic_energy=feats["acoustic_spectrum"]["low_band_energy"])
    assert res["primary_source"] == "Traffic Exhaust"
    assert res["confidence"] > 0.65
    assert "Traffic Exhaust" in res["probabilities"]


# ---------------------------------------------------------------------------
# 2. Hyperlocal Micro-Plume Gaussian Dispersion Vectoring Tests
# ---------------------------------------------------------------------------

def test_plume_vectoring_isolated_node():
    engine = MicroPlumeVectorEngine(default_lat=20.3540, default_lon=85.8180)
    feats = {
        "pm25": 85.0,
        "pm10": 130.0,
        "tmp": 32.0,
        "hum": 55.0,
        "pm_ratio": 0.65,
        "baro_hpa": 1011.2,
        "lux": 60000.0  # Daytime bright solar
    }
    source_attribution = {
        "primary_source": "Garbage Burning",
        "confidence": 0.91
    }
    plume = engine.estimate_plume_origin(feats, source_attribution)

    assert plume["active_plume"] is True
    assert 0.0 <= plume["bearing_deg"] <= 360.0
    assert plume["cardinal"] in [c[0] for c in MicroPlumeVectorEngine.CARDINALS]
    assert plume["distance_m"] > 0
    assert any(w in plume["distance_category"] for w in ["Zone", "Advection", "Proximity", "Sector"])
    assert "dispatch_directive" in plume
    assert "Garbage Burning" in plume["source"]
    assert "dispersion_model" in plume
    assert plume["dispersion_model"]["plume_width_m"] > 0


def test_plume_vectoring_mesh_triangulation():
    engine = MicroPlumeVectorEngine(default_lat=20.3540, default_lon=85.8180)
    feats = {
        "pm25": 50.0,
        "pm10": 90.0,
        "tmp": 28.0,
        "hum": 65.0,
        "pm_ratio": 0.55
    }
    source_attribution = {
        "primary_source": "Construction Dust",
        "confidence": 0.82
    }
    # Neighbor is East and has higher concentration -> plume originates East of us
    mesh_neighbors = [
        {
            "node_id": "UNO-Q-NODE-02",
            "name": "East Gate Station",
            "lat": 20.3540,
            "lon": 85.8220,
            "pm25": 140.0
        }
    ]
    plume = engine.estimate_plume_origin(feats, source_attribution, mesh_neighbors=mesh_neighbors)
    assert plume["active_plume"] is True
    # Should point generally Eastward (between 60 and 120 deg)
    assert 60.0 <= plume["bearing_deg"] <= 120.0
    assert "E" in plume["cardinal"]


# ---------------------------------------------------------------------------
# 3. Model Predictive Control (MPC) Smart Preemptive Actuation Tests
# ---------------------------------------------------------------------------

def test_mpc_preemptive_actuation():
    engine = RulesEngine(mcu_bridge=None)
    current_features = {
        "pm25": 22.0,
        "pm10": 40.0,
        "co2": 450.0,
        "aqi": 55
    }
    source_info = {"primary_source": "Clean Baseline"}
    forecast = {
        "+1h": {"pm25": 65.0, "pm10": 110.0, "co2": 480.0},
        "+2h": {"pm25": 88.0, "pm10": 145.0, "co2": 510.0}
    }

    # Evaluate with forecast
    engine.evaluate(current_features, source_info, forecast=forecast)
    status = engine.get_status()
    mpc = status.get("mpc_preemption", {})

    assert mpc["enabled"] is True
    assert mpc["preemption_active"] is True
    assert mpc["predicted_metric"] == "pm25"
    assert mpc["lead_time_min"] in [20, 25]
    # Relay 2 (Purifier) should be preemptively triggered
    assert engine.relays[2]["state"] is True


# ---------------------------------------------------------------------------
# 4. Offline Conversational Voice Assistant ("AeroSense Voice") Tests
# ---------------------------------------------------------------------------

def test_voice_assistant_grounded_queries():
    llm = LLMEngine(default_profile="Campus")
    context = {
        "features": {
            "aqi": 115,
            "pm25": 72.0,
            "pm10": 130.0,
            "co2": 610.0,
            "voc": 180.0,
            "co": 3.4,
            "pm_ratio": 0.62,
            "cdi_score": 25
        },
        "source_attribution": {
            "primary_source": "Garbage Burning",
            "confidence": 0.88
        },
        "plume": {
            "bearing_deg": 240.0,
            "cardinal": "WSW",
            "distance_m": 150
        }
    }

    # Query 1: Smell / Smoke
    res_smoke = llm.answer_natural_query("Why does it smell like smoke outside?", context=context, profile="Campus")
    assert "answer" in res_smoke
    assert "action" in res_smoke
    assert "ssml" in res_smoke
    assert "<speak>" in res_smoke["ssml"]
    assert "burning" in res_smoke["answer"].lower() or "smoke" in res_smoke["answer"].lower()
    assert "WSW" in res_smoke["answer"] or "240" in res_smoke["answer"]

    # Query 2: Outdoor workout / run
    res_run = llm.answer_natural_query("Can I go for a jog right now?", context=context, profile="Campus")
    assert "not recommended" in res_run["answer"].lower() or "avoid" in res_run["answer"].lower() or "indoor" in res_run["action"].lower()

    # Query 3: Window opening
    res_win = llm.answer_natural_query("Should I open the windows to ventilate?", context=context, profile="Campus")
    assert "close" in res_win["answer"].lower() or "seal" in res_win["answer"].lower() or "elevated" in res_win["answer"].lower()


# ---------------------------------------------------------------------------
# 5. Tamper-Proof Cryptographic SHA-256 Merkle Audit Ledger Tests
# ---------------------------------------------------------------------------

def test_cryptographic_audit_ledger_and_tamper_detection(tmp_path):
    db_file = str(tmp_path / "test_audit.db")
    storage = EdgeStorageEngine(db_path=db_file)

    # Log 5 sample records
    for i in range(5):
        feats = {
            "pm25": 12.0 + i,
            "pm10": 20.0 + i,
            "co2": 410.0 + i,
            "no2": 0.02,
            "voc": 35.0,
            "aqi": 30 + i
        }
        src = {"primary_source": "Clean Baseline", "confidence": 0.95}
        storage.log_telemetry(feats, src)

    # Record Block 1
    b1 = storage.record_audit_block(period_hours=1)
    assert b1["block_index"] == 1
    assert len(b1["merkle_root"]) == 64
    assert len(b1["block_hash"]) == 64
    assert b1["prev_hash"].startswith("GENESIS_BLOCK")

    # Record Block 2
    for i in range(3):
        feats = {"pm25": 14.0, "pm10": 25.0, "co2": 420.0, "no2": 0.02, "voc": 40.0, "aqi": 35}
        storage.log_telemetry(feats, {"primary_source": "Clean Baseline", "confidence": 0.95})
    b2 = storage.record_audit_block(period_hours=1)
    assert b2["block_index"] == 2
    assert b2["prev_hash"] == b1["block_hash"]

    # Verify ledger integrity
    audit = storage.verify_audit_ledger()
    assert audit["valid"] is True
    assert audit["integrity_status"] == "SECURE_VERIFIED"
    assert audit["total_blocks"] == 2

    # Export regulatory certificate
    cert = storage.export_audit_certificate()
    assert cert["integrity_verified"] is True
    assert cert["latest_block_hash"] == b2["block_hash"]
    assert "CPCB" in audit["proof_standard"] or "EPA" in audit["proof_standard"]

    # Now simulate a malicious tamper: alter Block 1's PM2.5 in SQLite directly
    with storage._connect() as conn:
        conn.execute("UPDATE audit_ledger SET avg_pm25 = 999.9 WHERE block_index = 1;")
        conn.commit()

    # Re-verify ledger: should instantly flag TAMPER_DETECTED!
    tamper_audit = storage.verify_audit_ledger()
    assert tamper_audit["valid"] is False
    assert tamper_audit["integrity_status"] == "TAMPER_DETECTED"
    assert tamper_audit["tampered_block_index"] == 1
