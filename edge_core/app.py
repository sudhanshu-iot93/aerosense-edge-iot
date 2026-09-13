"""
app.py
======
AeroSense Edge Core Daemon - Running on Arduino UNO Q (Qualcomm QRB2210 Linux).
Coordinates:
 1. Deterministic Sensor Ingestion from STM32U585 MCU Bridge
 2. Real-Time Stoichiometric Feature Pipeline & International AQI Calculation (NAQI, US EPA, CAQI, WHO)
 3. Edge AI Source Fingerprint Classification
 4. On-Device Hyperlocal Time Series Forecasting (1-6h)
 5. Anywhere Multi-Environment Context-Aware Advisory Generation (8 Profiles)
 6. Smart Multi-Metric Automation & Relay Actuation Engine
 7. Pure-Python Zero-Dependency MQTT Publisher & Webhook Alert Dispatcher
 8. 30-Day Circular SQLite Storage & Compliance Audit Summary
 9. Zero-Cloud Multi-Node Mesh Map Aggregation
 10. Embedded Web Dashboard & REST Server
"""

import functools
import io
import json
import logging
import os
import signal
import sys
import time
import threading
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# ---------------------------------------------------------------------------
# Logging setup
# ---------------------------------------------------------------------------
_LOG_LEVEL = os.environ.get("AEROSENSE_LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=getattr(logging, _LOG_LEVEL, logging.INFO),
    format="%(asctime)s [%(levelname)-8s] %(name)s: %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S"
)
logger = logging.getLogger("aerosense.app")

# Ensure local imports work cleanly
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "edge_ai"))
sys.path.append(os.path.dirname(__file__))

from feature_pipeline        import FeaturePipeline
from source_classifier       import SourceClassifier
from timeseries_forecaster   import TimeSeriesForecaster
from llm_engine              import LLMEngine
from advisory_engine         import AdvisoryEngine
from storage_engine          import EdgeStorageEngine
from compression             import DeltaDeltaCompressor
from mesh_node               import MeshNode
from mcu_bridge              import MCUBridge
from rules_engine            import RulesEngine
from mqtt_client             import MQTTPublisher
from health_exposure_tracker  import HealthExposureTracker
from anomaly_detector         import AnomalyDetector
from plume_vectoring          import MicroPlumeVectorEngine
# v1.5.0 Tier-1 Enhancements
from pollution_credit_score   import PollutionCreditScorer
from circadian_scheduler      import CircadianScheduler
from smart_notification_filter import SmartNotificationFilter

__version__ = "1.5.0"


# ---------------------------------------------------------------------------
# Core Daemon
# ---------------------------------------------------------------------------
class AeroSenseEdgeDaemon:
    def __init__(self, port: int = 8000, db_path: str = "aerosense_edge.db"):
        self.port    = port
        self.db_path = db_path

        logger.info("Initializing AeroSense Edge AI Core v%s …", __version__)
        self.storage = EdgeStorageEngine(db_path=self.db_path)

        # 1. Deployment Profile & International Standard
        self.active_profile  = self.storage.get_config("active_profile", "Campus")
        self.active_standard = self.storage.get_config("active_standard", "NAQI")

        # 2. Station Metadata
        self.station_info = self.storage.get_config("station_info", {
            "node_id": "UNO-Q-NODE-01",
            "name": "Central Campus Station",
            "zone": "Academic Quad",
            "lat": 20.3540,
            "lon": 85.8180,
            "elevation_m": 45,
            "is_indoor": False
        })

        # 3. Intelligence Pipelines
        self.feature_pipeline = FeaturePipeline(active_standard=self.active_standard)
        saved_calib = self.storage.get_config("sensor_calibration", None)
        if saved_calib:
            self.feature_pipeline.update_calibration(saved_calib)

        self.classifier       = SourceClassifier()
        self.forecaster       = TimeSeriesForecaster()
        self.llm_engine       = LLMEngine(default_profile=self.active_profile)
        self.mesh             = MeshNode(
            node_id=self.station_info.get("node_id", "UNO-Q-NODE-01"),
            node_name=self.station_info.get("name", "Central Academic Quad"),
            lat=self.station_info.get("lat", 20.3540),
            lon=self.station_info.get("lon", 85.8180)
        )
        self.mcu_bridge = MCUBridge(simulation_mode=True)

        # 4. Smart Automation Rules Engine
        saved_webhook = self.storage.get_config("webhook_url", "")
        self.rules_engine = RulesEngine(mcu_bridge=self.mcu_bridge, webhook_url=saved_webhook)
        self.rules_engine.load_profile_rules(self.active_profile)
        saved_rules = self.storage.get_config("custom_rules", None)
        if saved_rules:
            self.rules_engine.rules = saved_rules

        # 5. Pure-Python Zero-Dependency MQTT Publisher
        mqtt_cfg = self.storage.get_config("mqtt_config", {
            "host": "localhost",
            "port": 1883,
            "topic_prefix": "aerosense",
            "enabled": False
        })
        self.mqtt = MQTTPublisher(
            host=mqtt_cfg.get("host", "localhost"),
            port=mqtt_cfg.get("port", 1883),
            topic_prefix=mqtt_cfg.get("topic_prefix", "aerosense"),
            enabled=mqtt_cfg.get("enabled", False)
        )

        # Feature 1: Cumulative Health Exposure Tracker
        self.health_tracker = HealthExposureTracker()

        # Feature 6: Anomaly Detector
        self.anomaly_detector = AnomalyDetector(baseline_window=60, cooldown_seconds=300)

        # Feature 7: Micro-Plume Gaussian Dispersion & Origin Vectoring Engine
        self.plume_engine = MicroPlumeVectorEngine(
            default_lat=float(self.station_info.get("lat", 20.3540)),
            default_lon=float(self.station_info.get("lon", 85.8180))
        )

        # v1.5.0 — Tier-1 Enhancements
        # Feature A: Personal Pollution Credit Scorer
        saved_profile = self.storage.get_config("household_profile", "adult")
        self.credit_scorer = PollutionCreditScorer(default_profile=saved_profile)
        self.credit_scorer.inject_history_for_demo()   # pre-seed 7-day demo history

        # Feature D: Sleep & Circadian Mode
        sleep_cfg = self.storage.get_config("sleep_config", {})
        self.circadian = CircadianScheduler(
            sleep_start_hour=int(sleep_cfg.get("sleep_start_hour", 22)),
            sleep_end_hour=int(sleep_cfg.get("sleep_end_hour", 6)),
            enabled=bool(sleep_cfg.get("enabled", True))
        )

        # Feature C: Smart Notification Intelligence
        notif_cfg = self.storage.get_config("notification_filter_config", {})
        self.notification_filter = SmartNotificationFilter(
            sigma_threshold=float(notif_cfg.get("sigma_threshold", 2.5)),
            fatigue_cap=int(notif_cfg.get("fatigue_cap", 70)),
            cooldown_sec=int(notif_cfg.get("cooldown_sec", 300))
        )

        # Thread-safe state lock
        self._state_lock = threading.Lock()

        # Shared live state
        self._latest_state: dict = {
            "telemetry":         {},
            "features":          {},
            "source_attribution":{},
            "forecast":          {},
            "advisory":          {},
            "plume":             {},
            "mpc_status":        {},
            "mesh_topology":     [],
            "compression_stats": {},
            "active_profile":    self.active_profile,
            "active_standard":   self.active_standard,
            "station_info":      self.station_info,
            "rules_status":      self.rules_engine.get_status(),
            "mqtt_status":       self.mqtt.get_status(),
            "system_info": {
                "version":            __version__,
                "hardware":           "Arduino UNO Q",
                "mpu":                "Qualcomm QRB2210 Quad Cortex-A53 @ 1.3GHz",
                "mcu":                "STM32U585 Cortex-M33 @ 160MHz",
                "os":                 "Debian Linux (Embedded Edge)",
                "ai_engine":          "Quantized Edge AI (TFLite / ONNX Ready)",
                "cloud_dependency":   "0% (Fully Autonomous Offline)",
                "uptime_seconds":     0,
                "record_count":       0
            }
        }
        self.start_time = time.time()
        self._maintenance_timer: threading.Timer | None = None
        self.mcu_bridge.register_callback(self._on_telemetry_received)

    # ------------------------------------------------------------------
    # Telemetry Processing Pipeline
    # ------------------------------------------------------------------

    def _on_telemetry_received(self, raw_telemetry: dict):
        """Called every second upon receiving a new MCU frame."""
        try:
            # 1. Feature Engineering & Selected International AQI calculation
            features = self.feature_pipeline.extract_features(raw_telemetry)

            # 2. Source Attribution Classification
            acoustic = raw_telemetry.get("acoustic", 0.0)
            source_attribution = self.classifier.classify(features, acoustic_traffic_energy=acoustic)

            # 3. Time Series Forecasting
            self.forecaster.record_reading(
                pm25=features["pm25"],
                pm10=features["pm10"],
                temp=features["tmp"],
                hum=features["hum"],
                timestamp=raw_telemetry.get("timestamp", time.time())
            )
            forecast = self.forecaster.forecast(
                current_pm25=features["pm25"],
                current_pm10=features["pm10"],
                current_temp=features["tmp"],
                current_hum=features["hum"]
            )

            # 4. Anywhere Context-Aware Advisory Generation for Active Profile
            advisory = self.llm_engine.generate_advisory(
                features, source_attribution, forecast, profile=self.active_profile
            )

            # 5. Smart Multi-Metric Automation & Relay Actuation (with MPC Lookahead Preemption)
            self.rules_engine.evaluate(features, source_attribution, forecast=forecast)

            # 5b. Micro-Plume Gaussian Dispersion & Origin Vectoring
            mesh_neighbors = self.mesh.get_mesh_topology()
            plume = self.plume_engine.estimate_plume_origin(
                features, source_attribution, mesh_neighbors=mesh_neighbors
            )

            # 6. Local Storage Logging (Zero Cloud)
            self.storage.log_telemetry(features, source_attribution)

            # 7. Peer Mesh State Update
            self.mesh.update_local_reading(features, source_attribution)

            # 8. Pure-Python Zero-Cloud MQTT Publish
            self.mqtt.publish_telemetry(features, source_attribution)

            # Feature 1: Record reading for health exposure tracking
            self.health_tracker.record_reading(
                pm25=features["pm25"],
                source=source_attribution.get("primary_source", "Clean Baseline")
            )

            # Feature 6: Record for anomaly detection + persist if triggered
            self.anomaly_detector.record(
                pm25=features["pm25"],
                voc=features.get("voc", 0.0),
                co=features.get("co", 0.0)
            )
            anomaly_event = self.anomaly_detector.check(features, source_attribution)
            if anomaly_event:
                self.storage.save_incident(anomaly_event)
                logger.warning("Anomaly persisted: %s", anomaly_event["type"])

            # v1.5.0 Feature A: Feed credit scorer
            self.credit_scorer.record_reading_live(
                pm25=features["pm25"],
                voc=features.get("voc", 0.0),
                co2=features.get("co2", 400.0),
                no2=features.get("no2", 0.0)
            )

            # v1.5.0 Feature C: Feed smart notification baseline
            self.notification_filter.record_baseline("pm25", features["pm25"])
            self.notification_filter.record_baseline("aqi",  features.get("aqi", 0))
            self.notification_filter.record_baseline("co2",  features.get("co2", 400.0))
            self.notification_filter.record_baseline("voc",  features.get("voc", 0.0))

            # v1.5.0 Feature D: Tick circadian scheduler
            wake_report = self.circadian.tick(
                pm25=features["pm25"],
                aqi=int(features.get("aqi", 0))
            )
            if wake_report:
                logger.info("Wake report generated: sleep_score=%d",
                            wake_report.get("sleep_quality_score", 0))

            # 9. Update Live State (thread-safe)
            with self._state_lock:
                self._latest_state["telemetry"]          = raw_telemetry
                self._latest_state["features"]           = features
                self._latest_state["source_attribution"] = source_attribution
                self._latest_state["forecast"]           = forecast
                self._latest_state["advisory"]           = advisory
                self._latest_state["plume"]              = plume
                self._latest_state["mpc_status"]         = self.rules_engine.get_status().get("mpc_preemption", {})
                self._latest_state["mesh_topology"]      = self.mesh.get_mesh_topology()
                self._latest_state["active_profile"]     = self.active_profile
                self._latest_state["active_standard"]    = self.active_standard
                self._latest_state["rules_status"]       = self.rules_engine.get_status()
                self._latest_state["station_info"]       = self.station_info
                self._latest_state["mqtt_status"]        = self.mqtt.get_status()
                self._latest_state["system_info"]["uptime_seconds"] = int(time.time() - self.start_time)
                self._latest_state["system_info"]["record_count"]   = self.storage.get_record_count()

        except Exception:
            logger.exception("Unhandled exception in telemetry pipeline")

    # ------------------------------------------------------------------
    # Public API Helpers
    # ------------------------------------------------------------------

    def get_live_data(self) -> dict:
        recent_records = self.storage.get_recent_history(limit=30)
        stats = DeltaDeltaCompressor.compute_compression_stats(recent_records) if recent_records else {}
        with self._state_lock:
            state = dict(self._latest_state)
        state["compression_stats"] = stats
        return state

    def set_profile(self, profile: str) -> bool:
        if profile in AdvisoryEngine.PROFILES:
            self.active_profile = profile
            self.llm_engine.set_profile(profile)
            self.rules_engine.load_profile_rules(profile)
            self.storage.set_config("active_profile", profile)
            logger.info("Switched active profile to '%s'", profile)
            return True
        return False

    def set_standard(self, standard: str) -> bool:
        if self.feature_pipeline.set_standard(standard):
            self.active_standard = standard
            self.storage.set_config("active_standard", standard)
            logger.info("Switched active AQI standard to '%s'", standard)
            return True
        return False

    def update_calibration(self, calib_dict: dict):
        self.feature_pipeline.update_calibration(calib_dict)
        self.storage.set_config("sensor_calibration", self.feature_pipeline.calibration)

    def set_station_info(self, info: dict):
        self.station_info.update(info)
        self.storage.set_config("station_info", self.station_info)
        if "lat" in info and "lon" in info:
            self.mesh.lat = float(info["lat"])
            self.mesh.lon = float(info["lon"])
        if "name" in info:
            self.mesh.node_name = str(info["name"])

    def configure_mqtt(self, cfg: dict):
        self.mqtt.configure(
            host=cfg.get("host", cfg.get("broker", "localhost")),
            port=int(cfg.get("port", 1883)),
            topic_prefix=cfg.get("topic_prefix", "aerosense"),
            enabled=bool(cfg.get("enabled", True))
        )
        self.storage.set_config("mqtt_config", cfg)

    def set_webhook_url(self, url: str):
        self.rules_engine.set_webhook_url(url)
        self.storage.set_config("webhook_url", url)

    def inject_scenario(self, scenario_name: str):
        self.mcu_bridge.set_simulation_scenario(scenario_name)

    # ------------------------------------------------------------------
    # Maintenance
    # ------------------------------------------------------------------

    def _run_maintenance(self):
        try:
            self.storage.prune_old_data()
            self.storage.compute_hourly_summary()
            self.storage.record_audit_block(period_hours=1)
        except Exception:
            logger.exception("Error during periodic maintenance")
        finally:
            self._maintenance_timer = threading.Timer(3600, self._run_maintenance)
            self._maintenance_timer.daemon = True
            self._maintenance_timer.start()

    def start(self):
        self.mcu_bridge.start()
        try:
            self.storage.verify_audit_ledger()
        except Exception:
            logger.exception("Error initializing audit ledger")
        self._maintenance_timer = threading.Timer(3600, self._run_maintenance)
        self._maintenance_timer.daemon = True
        self._maintenance_timer.start()
        logger.info("AeroSense Edge Daemon running on port %d", self.port)

    def stop(self):
        logger.info("Shutting down AeroSense Edge Daemon …")
        self.mcu_bridge.stop()
        if self._maintenance_timer:
            self._maintenance_timer.cancel()
        logger.info("Daemon stopped cleanly.")


# ---------------------------------------------------------------------------
# Embedded HTTP Server Handler
# ---------------------------------------------------------------------------
class AeroSenseHandler(SimpleHTTPRequestHandler):
    daemon_instance: AeroSenseEdgeDaemon = None

    def _send_json(self, data_dict: dict, status_code: int = 200):
        body = json.dumps(data_dict, default=str).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type",   "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control",  "no-cache, no-store, must-revalidate")
        self.end_headers()
        self.wfile.write(body)

    def _send_error_json(self, status_code: int, message: str):
        self._send_json({"error": message, "status": status_code}, status_code)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin",  "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    # ----- GET ------------------------------------------------------------

    def do_GET(self):
        parsed     = urlparse(self.path)
        clean_path = parsed.path.rstrip("/")

        if clean_path == "/api/live":
            self._send_json(self.daemon_instance.get_live_data())

        elif clean_path == "/api/health":
            uptime = int(time.time() - self.daemon_instance.start_time)
            self._send_json({
                "status":  "ok",
                "version": __version__,
                "uptime_seconds": uptime,
                "uptime_human":   f"{uptime // 3600}h {(uptime % 3600) // 60}m {uptime % 60}s",
                "record_count":   self.daemon_instance.storage.get_record_count(),
                "simulation_mode": self.daemon_instance.mcu_bridge.simulation_mode,
                "current_scenario": self.daemon_instance.mcu_bridge.current_scenario,
                "active_profile":  self.daemon_instance.active_profile,
                "active_standard": self.daemon_instance.active_standard
            })

        elif clean_path == "/api/profiles":
            self._send_json({
                "profiles": AdvisoryEngine.PROFILES,
                "active_profile": self.daemon_instance.active_profile
            })

        elif clean_path == "/api/standards":
            self._send_json({
                "standards": FeaturePipeline.STANDARDS,
                "active_standard": self.daemon_instance.active_standard
            })

        elif clean_path == "/api/calibration":
            self._send_json({
                "calibration": self.daemon_instance.feature_pipeline.calibration
            })

        elif clean_path == "/api/rules":
            self._send_json(self.daemon_instance.rules_engine.get_status())

        elif clean_path == "/api/station":
            self._send_json(self.daemon_instance.station_info)

        elif clean_path == "/api/mqtt":
            self._send_json(self.daemon_instance.mqtt.get_status())

        elif clean_path == "/api/history":
            records = self.daemon_instance.storage.get_recent_history(limit=60)
            self._send_json(records)

        elif clean_path == "/api/mesh":
            topology = self.daemon_instance.mesh.get_mesh_topology()
            self._send_json(topology)

        elif clean_path == "/api/compress_demo":
            records    = self.daemon_instance.storage.get_recent_history(limit=50)
            compressed = DeltaDeltaCompressor.compress_records(records)
            stats      = DeltaDeltaCompressor.compute_compression_stats(records)
            self._send_json({
                "stats":                stats,
                "compressed_hex_sample": compressed[:64].hex() if compressed else ""
            })

        elif clean_path == "/api/export/audit-report":
            audit = self.daemon_instance.storage.get_compliance_audit_summary(hours=24)
            audit["station_info"] = self.daemon_instance.station_info
            audit["active_profile"] = self.daemon_instance.active_profile
            audit["active_standard"] = self.daemon_instance.active_standard
            self._send_json(audit)

        elif clean_path == "/api/export/csv":
            records = self.daemon_instance.storage.get_recent_history(limit=500)
            import csv
            output = io.StringIO()
            if records:
                writer = csv.DictWriter(output, fieldnames=list(records[0].keys()))
                writer.writeheader()
                writer.writerows(records)
            body = output.getvalue().encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/csv; charset=utf-8")
            self.send_header("Content-Disposition", 'attachment; filename="aerosense_edge_telemetry.csv"')
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(body)

        # Advanced Category-Defining Edge AI Endpoints:
        elif clean_path == "/api/plume":
            plume = self.daemon_instance._latest_state.get("plume")
            if not plume or not plume.get("active_plume"):
                feats = self.daemon_instance._latest_state.get("features", {})
                src = self.daemon_instance._latest_state.get("source_attribution", {})
                mesh_neighbors = self.daemon_instance.mesh.get_mesh_topology()
                plume = self.daemon_instance.plume_engine.estimate_plume_origin(
                    feats, src, mesh_neighbors=mesh_neighbors
                )
            self._send_json(plume)

        elif clean_path == "/api/audio-spectrum":
            feats = self.daemon_instance._latest_state.get("features", {})
            self._send_json({
                "acoustic_spectrum": feats.get("acoustic_spectrum", {}),
                "optical_haze": feats.get("optical_haze", {})
            })

        elif clean_path == "/api/mpc-status":
            mpc = self.daemon_instance.rules_engine.get_status().get("mpc_preemption", {})
            self._send_json(mpc)

        elif clean_path == "/api/export/ledger":
            ledger = self.daemon_instance.storage.verify_audit_ledger()
            self._send_json(ledger)

        elif clean_path == "/api/export/certificate":
            cert = self.daemon_instance.storage.export_audit_certificate()
            self._send_json(cert)

        # v1.5.0 Tier-1: Pollution Credit Score
        elif clean_path == "/api/health-score":
            score = self.daemon_instance.credit_scorer.compute_score()
            self._send_json(score)

        # v1.5.0 Tier-1: Sleep & Circadian Mode
        elif clean_path == "/api/sleep-mode":
            status = self.daemon_instance.circadian.get_status()
            self._send_json(status)

        # v1.5.0 Tier-1: Smart Notification Intelligence
        elif clean_path == "/api/notification-intelligence":
            intel = self.daemon_instance.notification_filter.get_status()
            self._send_json(intel)

        elif clean_path in (
            "/api/health-exposure",
            "/api/safe-windows",
            "/api/source-timeline",
            "/api/streak",
            "/api/daily-briefing",
            "/api/incidents"
        ):
            params = parse_qs(parsed.query)
            self._handle_get(clean_path, params)

        else:
            super().do_GET()

    # ----- POST -----------------------------------------------------------

    def do_POST(self):
        parsed     = urlparse(self.path)
        clean_path = parsed.path.rstrip("/")

        length = int(self.headers.get("Content-Length", 0))
        body   = self.rfile.read(length) if length > 0 else b"{}"
        try:
            payload = json.loads(body.decode("utf-8")) if body else {}
        except Exception:
            self._send_error_json(400, "Invalid JSON payload")
            return

        if clean_path == "/api/scenario":
            scenario = payload.get("scenario", "Clean Baseline")
            self.daemon_instance.inject_scenario(scenario)
            self._send_json({"status": "ok", "scenario": scenario})

        elif clean_path == "/api/profiles":
            profile = payload.get("profile", "Campus")
            if self.daemon_instance.set_profile(profile):
                self._send_json({"status": "ok", "active_profile": profile})
            else:
                self._send_error_json(400, f"Invalid profile. Choose from {AdvisoryEngine.PROFILES}")

        elif clean_path == "/api/standards":
            standard = payload.get("standard", "NAQI")
            if self.daemon_instance.set_standard(standard):
                self._send_json({"status": "ok", "active_standard": standard})
            else:
                self._send_error_json(400, f"Invalid standard. Choose from {FeaturePipeline.STANDARDS}")

        elif clean_path == "/api/calibration":
            calib = payload.get("calibration", {})
            self.daemon_instance.update_calibration(calib)
            self._send_json({"status": "ok", "calibration": self.daemon_instance.feature_pipeline.calibration})

        elif clean_path == "/api/rules":
            action = payload.get("action", "")
            if action == "add":
                rule = payload.get("rule", {})
                self.daemon_instance.rules_engine.add_rule(rule)
                self.daemon_instance.storage.set_config("custom_rules", self.daemon_instance.rules_engine.rules)
                self._send_json({"status": "ok", "rules": self.daemon_instance.rules_engine.rules})
            elif action == "delete":
                rule_id = payload.get("rule_id", "")
                self.daemon_instance.rules_engine.delete_rule(rule_id)
                self.daemon_instance.storage.set_config("custom_rules", self.daemon_instance.rules_engine.rules)
                self._send_json({"status": "ok", "rules": self.daemon_instance.rules_engine.rules})
            elif action == "toggle":
                rule_id = payload.get("rule_id", "")
                enabled = payload.get("enabled", True)
                self.daemon_instance.rules_engine.toggle_rule(rule_id, enabled)
                self.daemon_instance.storage.set_config("custom_rules", self.daemon_instance.rules_engine.rules)
                self._send_json({"status": "ok", "rules": self.daemon_instance.rules_engine.rules})
            elif action == "reload_defaults":
                self.daemon_instance.rules_engine.load_profile_rules(self.daemon_instance.active_profile)
                self.daemon_instance.storage.set_config("custom_rules", self.daemon_instance.rules_engine.rules)
                self._send_json({"status": "ok", "rules": self.daemon_instance.rules_engine.rules})
            elif action == "set_webhook":
                url = payload.get("webhook_url", "")
                self.daemon_instance.set_webhook_url(url)
                self._send_json({"status": "ok", "webhook_url": url})
            else:
                self._send_error_json(400, "Unknown rules action")

        # ---- New Feature Endpoints (POST) ----
        elif clean_path == "/api/incidents/confirm":
            inc_id = int(payload.get("id", 0))
            status = payload.get("status", "CONFIRMED")
            if inc_id and status in ("CONFIRMED", "DISMISSED"):
                ok = self.daemon_instance.storage.update_incident_status(inc_id, status)
                self._send_json({"status": "ok" if ok else "not_found", "id": inc_id, "new_status": status})
            else:
                self._send_error_json(400, "Invalid incident id or status")

        elif clean_path == "/api/relay":
            relay_num = int(payload.get("relay_num", 1))
            state     = bool(payload.get("state", False))
            manual    = bool(payload.get("manual", True))
            self.daemon_instance.rules_engine.set_relay_override(relay_num, state, manual=manual)
            self._send_json({"status": "ok", "relays": self.daemon_instance.rules_engine.relays})

        elif clean_path == "/api/station":
            self.daemon_instance.set_station_info(payload)
            self._send_json({"status": "ok", "station_info": self.daemon_instance.station_info})

        elif clean_path == "/api/mqtt":
            self.daemon_instance.configure_mqtt(payload)
            self._send_json({"status": "ok", "mqtt": self.daemon_instance.mqtt.get_status()})

        # Offline Conversational Voice Assistant
        elif clean_path == "/api/voice-query":
            query_str = payload.get("query") or payload.get("prompt") or ""
            if not query_str.strip():
                self._send_error_json(400, "Missing 'query' or 'prompt' parameter")
                return
            state = self.daemon_instance.get_live_data()
            ans = self.daemon_instance.llm_engine.answer_natural_query(
                query=query_str,
                context=state,
                profile=self.daemon_instance.active_profile
            )
            self._send_json(ans)

        # v1.5.0: Sleep Mode Configuration
        elif clean_path == "/api/sleep-mode":
            enabled     = payload.get("enabled", None)
            start_hour  = payload.get("sleep_start_hour", None)
            end_hour    = payload.get("sleep_end_hour", None)
            self.daemon_instance.circadian.configure(
                sleep_start_hour=int(start_hour) if start_hour is not None else None,
                sleep_end_hour=int(end_hour)   if end_hour   is not None else None,
                enabled=bool(enabled)           if enabled    is not None else None
            )
            cfg = {
                "sleep_start_hour": self.daemon_instance.circadian.sleep_start_hour,
                "sleep_end_hour":   self.daemon_instance.circadian.sleep_end_hour,
                "enabled":          self.daemon_instance.circadian.enabled,
            }
            self.daemon_instance.storage.set_config("sleep_config", cfg)
            self._send_json({"status": "ok", **self.daemon_instance.circadian.get_status()})

        # v1.5.0: Notification Filter Configuration
        elif clean_path == "/api/notification-filter":
            sigma   = payload.get("sigma_threshold", None)
            fatigue = payload.get("fatigue_cap", None)
            cooldown = payload.get("cooldown_sec", None)
            action  = payload.get("action", "")
            if action == "reset_fatigue":
                self.daemon_instance.notification_filter.reset_fatigue()
                self._send_json({"status": "ok", "fatigue_score": 0})
            else:
                self.daemon_instance.notification_filter.configure(
                    sigma_threshold=float(sigma)   if sigma   is not None else None,
                    fatigue_cap=int(fatigue)        if fatigue is not None else None,
                    cooldown_sec=int(cooldown)      if cooldown is not None else None,
                )
                cfg = {
                    "sigma_threshold": self.daemon_instance.notification_filter.sigma_threshold,
                    "fatigue_cap":     self.daemon_instance.notification_filter.fatigue_cap,
                    "cooldown_sec":    self.daemon_instance.notification_filter.cooldown_sec,
                }
                self.daemon_instance.storage.set_config("notification_filter_config", cfg)
                self._send_json({"status": "ok", **self.daemon_instance.notification_filter.get_status()})

        # v1.5.0: Household profile for credit scorer
        elif clean_path == "/api/household-profile":
            profile = payload.get("profile", "adult")
            self.daemon_instance.credit_scorer.set_profile(profile)
            self.daemon_instance.storage.set_config("household_profile", profile)
            self._send_json({"status": "ok", "profile": profile,
                             "score": self.daemon_instance.credit_scorer.compute_score()})

        else:
            self._send_error_json(404, f"Unknown endpoint: {clean_path}")

    def _handle_get(self, clean_path: str, params: dict):
        """Routes GET requests including new feature endpoints."""
        d = self.daemon_instance

        if clean_path == "/api/health-exposure":
            # Feature 1: Cumulative Health Exposure
            hourly_data = d.storage.get_hourly_source_timeline(hours=24).get("timeline", [])
            exposure = d.health_tracker.compute_daily_exposure(hourly_data or None)
            self._send_json(exposure)

        elif clean_path == "/api/safe-windows":
            # Feature 2: Safe Window Activity Planner
            feats = d._latest_state.get("features", {})
            windows = d.forecaster.find_safe_windows(
                current_pm25=feats.get("pm25", 15.0),
                current_pm10=feats.get("pm10", 30.0),
                current_temp=feats.get("tmp",  28.0),
                current_hum=feats.get("hum",   60.0),
            )
            self._send_json(windows)

        elif clean_path == "/api/source-timeline":
            # Feature 3: Source DNA Timeline
            hours = int(params.get("hours", ["24"])[0])
            timeline = d.storage.get_hourly_source_timeline(hours=min(hours, 72))
            self._send_json(timeline)

        elif clean_path == "/api/streak":
            # Feature 4: Compliance Streak & Zone Leaderboard
            streak = d.storage.get_compliance_streak()
            self._send_json(streak)

        elif clean_path == "/api/daily-briefing":
            # Feature 5: Smart Daily Briefing
            hour = time.localtime().tm_hour
            btype = "MORNING" if 4 <= hour < 14 else "EVENING"
            feats   = d._latest_state.get("features", {})
            src     = d._latest_state.get("source_attribution", {})
            fcast   = d._latest_state.get("forecast", {})
            hourly_data = d.storage.get_hourly_source_timeline(hours=24).get("timeline", [])
            exposure    = d.health_tracker.compute_daily_exposure(hourly_data or None)
            briefing    = d.llm_engine.generate_daily_briefing(
                current_telemetry=feats,
                source_info=src,
                forecast_info=fcast,
                health_exposure=exposure,
                profile=d.active_profile,
                briefing_type=btype,
            )
            self._send_json(briefing)

        elif clean_path == "/api/incidents":
            # Feature 6: Anomaly Incident Log
            limit = int(params.get("limit", ["30"])[0])
            incidents = d.storage.get_incidents(limit=min(limit, 100))
            unconfirmed = d.anomaly_detector.get_unconfirmed_count()
            self._send_json({
                "incidents":         incidents,
                "total_count":       len(incidents),
                "unconfirmed_count": unconfirmed,
            })

        else:
            self._send_error_json(404, f"Unknown GET endpoint: {clean_path}")

    def log_message(self, fmt, *args):
        if logger.isEnabledFor(logging.DEBUG):
            logger.debug("HTTP %s", fmt % args)


# ---------------------------------------------------------------------------
# Server Runner
# ---------------------------------------------------------------------------
def run_server(port: int = 8000):
    daemon = AeroSenseEdgeDaemon(port=port)
    daemon.start()

    for _ in range(5):
        time.sleep(0.2)

    dashboard_path  = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "web_dashboard"))
    handler_factory = functools.partial(AeroSenseHandler, directory=dashboard_path)
    AeroSenseHandler.daemon_instance = daemon

    httpd = HTTPServer(("", port), handler_factory)

    def _shutdown(signum, frame):
        logger.info("Signal %d received — shutting down …", signum)
        daemon.stop()
        httpd.server_close()
        sys.exit(0)

    signal.signal(signal.SIGINT,  _shutdown)
    try:
        signal.signal(signal.SIGTERM, _shutdown)
    except (OSError, AttributeError):
        pass

    banner = (
        "\n"
        "========================================================\n"
        "  AeroSense Edge Pro  *  v{ver}\n"
        "  Hardware : Arduino UNO Q (QRB2210 + STM32U585)\n"
        "  Profile  : {prof} Mode\n"
        "  Standard : {std}\n"
        "  Dashboard: http://localhost:{port}/\n"
        "  Health   : http://localhost:{port}/api/health\n"
        "  Credit   : http://localhost:{port}/api/health-score\n"
        "  Sleep    : http://localhost:{port}/api/sleep-mode\n"
        "  Alerts   : http://localhost:{port}/api/notification-intelligence\n"
        "  Zero Cloud Cost  *  100% On-Device AI Inference\n"
        "========================================================\n"
    ).format(ver=__version__, port=port, prof=daemon.active_profile, std=daemon.active_standard)
    print(banner, flush=True)

    logger.info("HTTP server listening on http://0.0.0.0:%d", port)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        _shutdown(signal.SIGINT, None)


if __name__ == "__main__":
    port = 8000
    if len(sys.argv) > 1 and sys.argv[1].isdigit():
        port = int(sys.argv[1])
    run_server(port)
