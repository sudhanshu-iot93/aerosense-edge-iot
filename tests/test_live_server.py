import json
import urllib.request
import urllib.parse
import threading
import time
import os
import sys
import functools
from http.server import HTTPServer
import pytest

sys.path.extend([
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..")),
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "edge_ai")),
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "edge_core"))
])

from edge_core.app import AeroSenseHandler, AeroSenseEdgeDaemon

TEST_PORT = 8999

@pytest.fixture(scope="module", autouse=True)
def run_server():
    daemon = AeroSenseEdgeDaemon(port=TEST_PORT)
    daemon.start()
    
    dashboard_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "web_dashboard"))
    handler_factory = functools.partial(AeroSenseHandler, directory=dashboard_path)
    AeroSenseHandler.daemon_instance = daemon

    server = HTTPServer(("127.0.0.1", TEST_PORT), handler_factory)
    t = threading.Thread(target=server.serve_forever, daemon=True)
    t.start()
    time.sleep(1.0) # Wait for initial telemetry tick
    yield
    daemon.stop()
    server.shutdown()

def get_json(path):
    req = urllib.request.Request(f"http://127.0.0.1:{TEST_PORT}{path}")
    with urllib.request.urlopen(req, timeout=3) as resp:
        assert resp.status == 200
        return json.loads(resp.read().decode("utf-8"))

def post_json(path, data):
    body = json.dumps(data).encode("utf-8")
    req = urllib.request.Request(
        f"http://127.0.0.1:{TEST_PORT}{path}",
        data=body,
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=3) as resp:
        assert resp.status == 200
        return json.loads(resp.read().decode("utf-8"))

def test_api_health():
    data = get_json("/api/health")
    assert data["status"] == "ok"
    assert "active_profile" in data
    assert "active_standard" in data

def test_api_profiles():
    data = get_json("/api/profiles")
    assert "profiles" in data
    assert "Campus" in data["profiles"]
    assert "Greenhouse" in data["profiles"]
    assert "Hospital" in data["profiles"]

    # Test setting profile
    resp = post_json("/api/profiles", {"profile": "Greenhouse"})
    assert resp["status"] == "ok"
    assert resp["active_profile"] == "Greenhouse"

def test_api_standards():
    data = get_json("/api/standards")
    assert "standards" in data
    assert "NAQI" in data["standards"]
    assert "WHO_2021" in data["standards"]

    # Test setting standard
    resp = post_json("/api/standards", {"standard": "WHO_2021"})
    assert resp["status"] == "ok"
    assert resp["active_standard"] == "WHO_2021"

def test_api_calibration():
    # Set calibration
    payload = {
        "calibration": {
            "pm25": {"scale": 1.05, "offset": -2.0, "enabled": True}
        }
    }
    resp = post_json("/api/calibration", payload)
    assert resp["status"] == "ok"
    assert resp["calibration"]["pm25"]["gain"] == 1.05

    # Get calibration
    data = get_json("/api/calibration")
    assert data["calibration"]["pm25"]["offset"] == -2.0

def test_api_rules_and_relays():
    # Fetch rules
    data = get_json("/api/rules")
    assert "rules" in data
    assert "relays" in data
    assert "1" in data["relays"]

    # Control relay override
    resp = post_json("/api/relay", {"relay_num": 1, "state": True, "manual": True})
    assert resp["status"] == "ok"
    assert resp["relays"]["1"]["state"] is True

def test_api_station_and_mqtt():
    # Update station metadata
    resp = post_json("/api/station", {"station_id": "STATION_UNIT_042", "station_name": "Test Lab"})
    assert resp["status"] == "ok"
    assert resp["station_info"]["station_id"] == "STATION_UNIT_042"

    # Configure MQTT
    resp = post_json("/api/mqtt", {"broker": "192.168.1.100", "port": 1883, "enabled": False})
    assert resp["status"] == "ok"
    assert resp["mqtt"]["broker"] == "192.168.1.100"

def test_api_live_universal():
    data = get_json("/api/live")
    assert "active_profile" in data
    assert "active_standard" in data
    assert "features" in data
    assert "rules_status" in data
    assert "relays" in data["rules_status"]
    # Check domain features exist
    features = data["features"]
    assert "vpd_kpa" in features
    assert "cdi_score" in features
    assert "infection_risk_score" in features

def test_api_audit_report():
    data = get_json("/api/export/audit-report")
    assert "station_info" in data
    assert "active_profile" in data
    assert "active_standard" in data
    assert "total_samples" in data
    assert "compliance_pct_who" in data
    assert "air_quality_status" in data

def test_api_plume():
    data = get_json("/api/plume")
    assert "active_plume" in data
    assert "bearing_deg" in data
    assert "cardinal" in data
    assert "distance_m" in data
    assert "dispatch_directive" in data

def test_api_audio_spectrum():
    data = get_json("/api/audio-spectrum")
    assert "acoustic_spectrum" in data
    assert "optical_haze" in data
    assert "bands" in data["acoustic_spectrum"]
    assert len(data["acoustic_spectrum"]["bands"]) == 16
    assert "visual_range_km" in data["optical_haze"]

def test_api_mpc_status():
    data = get_json("/api/mpc-status")
    assert "enabled" in data
    assert "preemption_active" in data

def test_api_export_ledger():
    data = get_json("/api/export/ledger")
    assert "valid" in data
    assert data["valid"] is True
    assert "integrity_status" in data
    assert data["integrity_status"] == "SECURE_VERIFIED"
    assert data["total_blocks"] >= 1

def test_api_export_certificate():
    data = get_json("/api/export/certificate")
    assert "certificate_id" in data
    assert data["integrity_verified"] is True
    assert "hardware_signature" in data

def test_api_voice_query():
    resp = post_json("/api/voice-query", {"query": "Why does it smell like smoke outside?"})
    assert "answer" in resp
    assert "action" in resp
    assert "ssml" in resp
    assert "<speak>" in resp["ssml"]
    assert "confidence" in resp

