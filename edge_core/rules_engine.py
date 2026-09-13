"""
rules_engine.py
===============
Smart Automation and Multi-Relay Rules Engine for Arduino UNO Q.
Evaluates multi-metric conditions on live telemetry every second to trigger:
  - Hardware Relays (Exhaust Fans, HEPA Purifiers, Misting Sprinklers, Alarms)
  - Webhook POST Alerts (Slack, Discord, Home Assistant, Node-RED)
  - Audio Siren / Speech Alerts
"""

import json
import logging
import time
import urllib.request
import urllib.error
from typing import Dict, Any, List, Optional

__all__ = ["RulesEngine"]

logger = logging.getLogger(__name__)


class RulesEngine:
    DEFAULT_PROFILE_RULES = {
        "Campus": [
            {
                "id": "rule_campus_fire",
                "name": "Garbage Fire Plume Sprinkler Misting",
                "metric": "primary_source",
                "operator": "==",
                "threshold": "Garbage Burning",
                "action": "relay_2",
                "action_type": "relay",
                "relay_num": 2,
                "relay_name": "Perimeter Mist Sprinklers",
                "enabled": True,
                "last_triggered": 0
            },
            {
                "id": "rule_campus_pm25",
                "name": "Severe Particulate Corridor Alert",
                "metric": "pm25",
                "operator": ">",
                "threshold": 120.0,
                "action": "webhook",
                "action_type": "webhook",
                "enabled": True,
                "last_triggered": 0
            }
        ],
        "Classroom": [
            {
                "id": "rule_class_co2",
                "name": "High Classroom CO2 Ventilation Flush",
                "metric": "co2",
                "operator": ">",
                "threshold": 1000.0,
                "action": "relay_1",
                "action_type": "relay",
                "relay_num": 1,
                "relay_name": "Fresh Air Intake Damper",
                "enabled": True,
                "last_triggered": 0
            }
        ],
        "Hospital": [
            {
                "id": "rule_hosp_sterile",
                "name": "ICU HEPA Filtration Booster",
                "metric": "pm25",
                "operator": ">",
                "threshold": 25.0,
                "action": "relay_2",
                "action_type": "relay",
                "relay_num": 2,
                "relay_name": "HEPA Terminal Filter",
                "enabled": True,
                "last_triggered": 0
            }
        ],
        "Industrial": [
            {
                "id": "rule_ind_toxic",
                "name": "Occupational Hazardous Gas Siren",
                "metric": "aqi",
                "operator": ">",
                "threshold": 180.0,
                "action": "relay_3",
                "action_type": "relay",
                "relay_num": 3,
                "relay_name": "Emergency Plant Siren",
                "enabled": True,
                "last_triggered": 0
            },
            {
                "id": "rule_ind_damper",
                "name": "Roof Exhaust Damper Extraction",
                "metric": "no2",
                "operator": ">",
                "threshold": 0.05,
                "action": "relay_1",
                "action_type": "relay",
                "relay_num": 1,
                "relay_name": "Industrial Exhaust Fan",
                "enabled": True,
                "last_triggered": 0
            }
        ],
        "Kitchen": [
            {
                "id": "rule_kitch_hood",
                "name": "Automatic Range Hood Booster",
                "metric": "voc",
                "operator": ">",
                "threshold": 150.0,
                "action": "relay_1",
                "action_type": "relay",
                "relay_num": 1,
                "relay_name": "Commercial Exhaust Hood",
                "enabled": True,
                "last_triggered": 0
            }
        ],
        "Greenhouse": [
            {
                "id": "rule_gh_misting",
                "name": "VPD Water Stress Fogging Mist",
                "metric": "vpd_kpa",
                "operator": ">",
                "threshold": 1.4,
                "action": "relay_2",
                "action_type": "relay",
                "relay_num": 2,
                "relay_name": "High-Pressure Fogger",
                "enabled": True,
                "last_triggered": 0
            },
            {
                "id": "rule_gh_circ",
                "name": "Low VPD Dehumidification Vent",
                "metric": "vpd_kpa",
                "operator": "<",
                "threshold": 0.5,
                "action": "relay_1",
                "action_type": "relay",
                "relay_num": 1,
                "relay_name": "HAF Circulation Fans",
                "enabled": True,
                "last_triggered": 0
            }
        ],
        "Transit": [
            {
                "id": "rule_transit_jets",
                "name": "Subway Platform Jet Fan Boost",
                "metric": "pm10",
                "operator": ">",
                "threshold": 140.0,
                "action": "relay_1",
                "action_type": "relay",
                "relay_num": 1,
                "relay_name": "Tunnel Axial Jet Fans",
                "enabled": True,
                "last_triggered": 0
            }
        ],
        "Residential": [
            {
                "id": "rule_home_purifier",
                "name": "Smart Bedroom Air Purifier Turbo",
                "metric": "pm25",
                "operator": ">",
                "threshold": 35.0,
                "action": "relay_2",
                "action_type": "relay",
                "relay_num": 2,
                "relay_name": "Home HEPA Purifier",
                "enabled": True,
                "last_triggered": 0
            }
        ]
    }

    def __init__(self, mcu_bridge=None, webhook_url: str = ""):
        self.mcu_bridge = mcu_bridge
        self.webhook_url = webhook_url
        self.active_profile = "Campus"
        self.rules: List[Dict[str, Any]] = []
        self.load_profile_rules("Campus")

        # Hardware relay states (4 channels on Arduino UNO Q)
        self.relays = {
            1: {"name": "Exhaust / Ventilation", "state": False, "manual_override": False},
            2: {"name": "Purifier / Misting",    "state": False, "manual_override": False},
            3: {"name": "Alarm Siren",            "state": False, "manual_override": False},
            4: {"name": "Auxiliary Damper",       "state": False, "manual_override": False}
        }
        self.execution_log: List[Dict[str, Any]] = []

        # Model Predictive Control (MPC) lookahead preemption engine
        self.mpc_status: Dict[str, Any] = {
            "enabled": True,
            "preemption_active": False,
            "predicted_metric": None,
            "predicted_val": 0.0,
            "lead_time_min": 0,
            "preemptive_action": "Monitoring 1-6h Forecast Horizon",
            "prevented_surge": False
        }

    def set_webhook_url(self, url: str):
        self.webhook_url = url.strip()
        logger.info("Automation webhook URL set to: %s", self.webhook_url)

    def load_profile_rules(self, profile: str):
        self.active_profile = profile
        default_rules = self.DEFAULT_PROFILE_RULES.get(profile, self.DEFAULT_PROFILE_RULES["Campus"])
        self.rules = [dict(r) for r in default_rules]
        logger.info("Loaded %d automation rules for profile '%s'", len(self.rules), profile)

    def get_rules(self) -> List[Dict[str, Any]]:
        return self.rules

    def add_rule(self, rule: Dict[str, Any]):
        if "id" not in rule:
            rule["id"] = f"rule_{int(time.time()*1000)}"
        rule["last_triggered"] = 0
        self.rules.append(rule)

    def delete_rule(self, rule_id: str) -> bool:
        initial = len(self.rules)
        self.rules = [r for r in self.rules if r.get("id") != rule_id]
        return len(self.rules) < initial

    def toggle_rule(self, rule_id: str, enabled: bool):
        for r in self.rules:
            if r.get("id") == rule_id:
                r["enabled"] = enabled

    def set_relay_override(self, relay_num: int, state: bool, manual: bool = True):
        if relay_num in self.relays:
            self.relays[relay_num]["state"] = state
            self.relays[relay_num]["manual_override"] = manual
            if self.mcu_bridge:
                self.mcu_bridge.send_actuation_command(relay_on=state)
            logger.info("Relay #%d manually overridden to %s", relay_num, "ON" if state else "OFF")

    def evaluate_mpc_preemption(self, features: Dict[str, Any], forecast: Optional[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Model Predictive Control (MPC) lookahead preemption engine.
        Anticipates pollution peaks 1-2 hours in advance and preemptively commands
        air purifiers (Relay 2) or ventilation flush (Relay 1) to create clean indoor buffer.
        """
        if not forecast:
            self.mpc_status["preemption_active"] = False
            return self.mpc_status

        # Lookahead +1h and +2h projections
        h1 = forecast.get("+1h") or forecast.get("1h") or {}
        h2 = forecast.get("+2h") or forecast.get("2h") or {}

        curr_pm25 = float(features.get("pm25", 15.0))
        pred_pm25_1 = float(h1.get("pm25", curr_pm25))
        pred_pm25_2 = float(h2.get("pm25", pred_pm25_1))
        max_pred_pm25 = max(pred_pm25_1, pred_pm25_2)

        curr_co2 = float(features.get("co2", 420.0))
        pred_co2 = float(h1.get("co2", curr_co2)) if "co2" in h1 else curr_co2

        preempt = False
        action_msg = "Monitoring 1-6h Forecast Horizon"
        metric = None
        val = 0.0
        lead_time = 0

        # Case A: PM2.5 surge predicted within 1-2 hours
        if max_pred_pm25 >= 50.0 and curr_pm25 < 45.0:
            preempt = True
            metric = "pm25"
            val = round(max_pred_pm25, 1)
            lead_time = 25
            action_msg = f"Preemptive Air Purifier Active (+1h PM2.5 Surge Predicted: {val} µg/m³)"

        # Case B: Classroom / Office CO2 surge predicted
        elif pred_co2 >= 950.0 and curr_co2 < 800.0:
            preempt = True
            metric = "co2"
            val = round(pred_co2, 0)
            lead_time = 20
            action_msg = f"Preemptive Fresh Air Damper Active (+1h CO2 Surge Predicted: {val:.0f} ppm)"

        self.mpc_status.update({
            "preemption_active": preempt,
            "predicted_metric": metric,
            "predicted_val": val,
            "lead_time_min": lead_time,
            "preemptive_action": action_msg,
            "prevented_surge": preempt or self.mpc_status.get("prevented_surge", False)
        })
        return self.mpc_status

    def evaluate(self, telemetry: Dict[str, Any], source_info: Dict[str, Any], forecast: Optional[Dict[str, Any]] = None):
        """Evaluates all rules and MPC lookahead against current telemetry frame."""
        now = time.time()
        primary_source = source_info.get("primary_source", "Clean Baseline")

        # Evaluate MPC preemption if forecast is available
        if forecast:
            self.evaluate_mpc_preemption(telemetry, forecast)

        # Flat values dict for fast evaluation
        eval_context = {
            "pm1":            telemetry.get("pm1", 0.0),
            "pm25":           telemetry.get("pm25", 0.0),
            "pm10":           telemetry.get("pm10", 0.0),
            "co2":            telemetry.get("co2", 0.0),
            "no2":            telemetry.get("no2", 0.0),
            "co":             telemetry.get("co", 0.0),
            "nh3":            telemetry.get("nh3", 0.0),
            "voc":            telemetry.get("voc", 0.0),
            "tmp":            telemetry.get("tmp", 0.0),
            "hum":            telemetry.get("hum", 0.0),
            "aqi":            telemetry.get("aqi", 0),
            "primary_source": primary_source,
            "vpd_kpa":        telemetry.get("vpd", {}).get("vpd_kpa", 1.0),
            "cdi_score":      telemetry.get("cdi", {}).get("cdi_score", 15),
            "infection_risk": telemetry.get("infection_risk", {}).get("infection_risk_score", 20)
        }

        # Auto-calculated relay demand states (if not in manual override)
        relay_demand = {1: False, 2: False, 3: False, 4: False}

        # Inject MPC preemptive demand
        if self.mpc_status.get("preemption_active"):
            if self.mpc_status.get("predicted_metric") == "pm25":
                relay_demand[2] = True  # Preemptively clean indoor air
            elif self.mpc_status.get("predicted_metric") == "co2":
                relay_demand[1] = True  # Preemptively ventilate

        for rule in self.rules:
            if not rule.get("enabled", True):
                continue

            metric = rule.get("metric", "")
            op = rule.get("operator", ">")
            thresh = rule.get("threshold", 0)

            actual_val = eval_context.get(metric)
            if actual_val is None:
                continue

            # Compare
            triggered = False
            try:
                if op == ">":
                    triggered = float(actual_val) > float(thresh)
                elif op == ">=":
                    triggered = float(actual_val) >= float(thresh)
                elif op == "<":
                    triggered = float(actual_val) < float(thresh)
                elif op == "<=":
                    triggered = float(actual_val) <= float(thresh)
                elif op == "==":
                    triggered = str(actual_val).lower() == str(thresh).lower()
                elif op == "!=":
                    triggered = str(actual_val).lower() != str(thresh).lower()
            except (ValueError, TypeError):
                triggered = False

            if triggered:
                action_type = rule.get("action_type", "relay")
                if action_type == "relay":
                    relay_num = int(rule.get("relay_num", 1))
                    if relay_num in relay_demand:
                        relay_demand[relay_num] = True

                # Rate-limit webhook dispatch to once every 60 seconds
                if action_type == "webhook" and (now - rule.get("last_triggered", 0)) > 60:
                    rule["last_triggered"] = now
                    self._dispatch_webhook(rule, actual_val)

                # Log event
                if (now - rule.get("last_triggered", 0)) > 30:
                    rule["last_triggered"] = now
                    self.execution_log.append({
                        "time": time.strftime("%H:%M:%S", time.localtime(now)),
                        "rule_name": rule.get("name"),
                        "metric": metric,
                        "value": actual_val,
                        "action": rule.get("action")
                    })
                    if len(self.execution_log) > 20:
                        self.execution_log.pop(0)

        # Apply demand to hardware relays (unless manual override is active)
        for r_num, demanded in relay_demand.items():
            if not self.relays[r_num]["manual_override"]:
                if self.relays[r_num]["state"] != demanded:
                    self.relays[r_num]["state"] = demanded
                    if self.mcu_bridge and r_num == 1:
                        self.mcu_bridge.send_actuation_command(relay_on=demanded)

    def _dispatch_webhook(self, rule: Dict[str, Any], val: Any):
        if not self.webhook_url:
            return
        payload = json.dumps({
            "event": "AEROSENSE_RULE_TRIGGERED",
            "rule": rule.get("name"),
            "metric": rule.get("metric"),
            "value": val,
            "threshold": rule.get("threshold"),
            "profile": self.active_profile,
            "timestamp": int(time.time())
        }).encode("utf-8")

        def _send():
            try:
                req = urllib.request.Request(
                    self.webhook_url,
                    data=payload,
                    headers={"Content-Type": "application/json", "User-Agent": "AeroSenseEdge/1.3"}
                )
                with urllib.request.urlopen(req, timeout=3.0) as resp:
                    logger.info("Webhook alert dispatched successfully (status %d)", resp.status)
            except Exception as exc:
                logger.warning("Webhook dispatch failed: %s", exc)

        import threading
        threading.Thread(target=_send, daemon=True, name="webhook-sender").start()

    def get_status(self) -> Dict[str, Any]:
        return {
            "active_profile": self.active_profile,
            "webhook_url": self.webhook_url,
            "relays": self.relays,
            "rules": self.rules,
            "mpc": self.mpc_status,
            "mpc_preemption": self.mpc_status,
            "recent_events": self.execution_log[-10:]
        }
