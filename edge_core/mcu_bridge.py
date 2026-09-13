"""
mcu_bridge.py
=============
IPC Bridge and Telemetry Receiver for STM32U585 MCU on Arduino UNO Q.
Listens to high-speed virtual serial stream or generates calibrated
hardware telemetry when in simulation / lab testing mode.
"""

import json
import logging
import time
import random
import threading
from typing import Dict, Any, Callable, Optional

__all__ = ["MCUBridge"]

logger = logging.getLogger(__name__)


class MCUBridge:
    def __init__(self, port: str = "/dev/ttyACM0", baudrate: int = 115200,
                 simulation_mode: bool = True, poll_interval: float = 1.0):
        self.port            = port
        self.baudrate        = baudrate
        self.simulation_mode = simulation_mode
        self.poll_interval   = poll_interval
        self.running         = False
        self.callbacks       = []
        self.current_scenario = "Clean Baseline"
        self._thread: Optional[threading.Thread] = None
        self.sim_time        = time.time()

        # Properly initialise transition counter (avoids getattr hack)
        self._transition_counter: int = 0

        # Base simulated parameters
        self._sim_state = {
            "pm1":  8.0,
            "pm25": 14.0,
            "pm10": 26.0,
            "co2":  418.0,
            "no2":  0.018,
            "co":   0.45,
            "nh3":  0.20,
            "voc":  28.0,
            "tmp":  26.5,
            "hum":  52.0,
            "prs":  1012.8,
            "bat":  96,
            "vin":  3.32,
            "hlth": 15,
            "acoustic": 0.1
        }

    def register_callback(self, callback: Callable[[Dict[str, Any]], None]):
        self.callbacks.append(callback)

    def set_simulation_scenario(self, scenario: str):
        """Allows real-time interactive injection of environmental events."""
        self.current_scenario    = scenario
        self._transition_counter = 8   # fast alpha for first 8 ticks
        logger.info("Injected Environmental Scenario: %s", scenario)

    def send_actuation_command(self, relay_on: bool):
        """Sends an actuation command to the MCU."""
        cmd = "ACTUATE_RELAY:1\n" if relay_on else "ACTUATE_RELAY:0\n"
        if not self.simulation_mode and getattr(self, '_ser', None) is not None:
            try:
                self._ser.write(cmd.encode("utf-8"))
            except Exception as e:
                logger.error("Failed to send actuation command: %s", e)
        else:
            logger.info("[SIMULATION] MCU Actuation Triggered: %s", cmd.strip())

    def start(self):
        self.running = True
        self._thread = threading.Thread(target=self._run_loop, daemon=True, name="mcu-bridge")
        self._thread.start()
        logger.info("MCU Bridge started (mode=%s)", "simulation" if self.simulation_mode else f"serial:{self.port}")

    def stop(self):
        self.running = False
        logger.info("MCU Bridge stop requested")

    def _dispatch(self, data: Dict[str, Any]):
        """Dispatch telemetry to all registered callbacks with individual exception isolation."""
        for cb in self.callbacks:
            try:
                cb(data)
            except Exception:
                logger.exception("Callback %s raised an exception; continuing", cb)

    def _run_loop(self):
        if not self.simulation_mode:
            try:
                import serial
                self._ser = serial.Serial(self.port, self.baudrate, timeout=1.0)
                logger.info("Connected to STM32U585 MCU on %s @ %d baud", self.port, self.baudrate)
                while self.running:
                    line = self._ser.readline().decode("utf-8", errors="ignore").strip()
                    if line.startswith("{") and line.endswith("}"):
                        try:
                            data = json.loads(line)
                            self._dispatch(data)
                        except json.JSONDecodeError:
                            logger.warning("Malformed JSON from MCU: %s", line[:80])
                self._ser.close()
                return
            except Exception as exc:
                logger.warning("Real serial failed (%s), falling back to Edge Simulation Engine", exc)
                self.simulation_mode = True

        # Simulation loop generating physics-based dynamic sensor readings
        logger.info("Simulation loop running (scenario=%s)", self.current_scenario)
        while self.running:
            data = self._generate_simulated_frame()
            self._dispatch(data)
            time.sleep(self.poll_interval)

    def _generate_simulated_frame(self) -> Dict[str, Any]:
        """Generates realistic sensor telemetry corresponding to current injected scenario."""
        s        = self._sim_state
        scenario = self.current_scenario

        # Target setpoints for different scenarios
        if scenario == "Traffic Jam":
            target_pm25 = 115.0
            target_pm10 = 150.0
            target_no2  = 0.085
            target_co   = 3.2
            target_voc  = 75.0
            target_co2  = 540.0
            target_acoustic = 0.85
        elif scenario == "Garbage Fire":
            target_pm25 = 240.0
            target_pm10 = 310.0
            target_no2  = 0.038
            target_co   = 6.5
            target_voc  = 260.0
            target_co2  = 680.0
            target_acoustic = 0.2
        elif scenario == "Construction Dust":
            target_pm25 = 45.0
            target_pm10 = 320.0
            target_no2  = 0.018
            target_co   = 0.5
            target_voc  = 25.0
            target_co2  = 420.0
            target_acoustic = 0.6
        elif scenario == "Cooking Smoke":
            target_pm25 = 85.0
            target_pm10 = 110.0
            target_no2  = 0.022
            target_co   = 1.8
            target_voc  = 280.0
            target_co2  = 1150.0
            target_acoustic = 0.1
        elif scenario == "Crop Residue":
            target_pm25 = 175.0
            target_pm10 = 210.0
            target_no2  = 0.028
            target_co   = 4.2
            target_voc  = 110.0
            target_co2  = 580.0
            target_acoustic = 0.15
        else:  # Clean Baseline / Fresh Air
            target_pm25 = 14.0
            target_pm10 = 24.0
            target_no2  = 0.015
            target_co   = 0.4
            target_voc  = 25.0
            target_co2  = 415.0
            target_acoustic = 0.1

        # Responsive transition alpha
        alpha = 0.55 if self._transition_counter > 0 else 0.25
        if self._transition_counter > 0:
            self._transition_counter -= 1

        s["pm25"] = max(1.0,  s["pm25"] * (1 - alpha) + target_pm25 * alpha + random.gauss(0, 1.2))
        s["pm10"] = max(s["pm25"] * 1.1, s["pm10"] * (1 - alpha) + target_pm10 * alpha + random.gauss(0, 2.0))
        s["pm1"]  = round(s["pm25"] * 0.72, 1)
        s["no2"]  = max(0.005, round(s["no2"] * (1 - alpha) + target_no2 * alpha + random.gauss(0, 0.002), 3))
        s["co"]   = max(0.1,   round(s["co"]  * (1 - alpha) + target_co  * alpha + random.gauss(0, 0.05), 2))
        s["voc"]  = max(5.0,   round(s["voc"] * (1 - alpha) + target_voc * alpha + random.gauss(0, 2.5), 1))
        s["co2"]  = max(380.0, round(s["co2"] * (1 - alpha) + target_co2 * alpha + random.gauss(0, 5.0), 1))
        s["tmp"]  = round(25.8 + random.gauss(0, 0.05), 2)
        s["hum"]  = round(54.2 + random.gauss(0, 0.15), 1)
        s["prs"]  = round(1013.2 + random.gauss(0, 0.1), 1)
        s["bat"]  = max(85, min(100, s["bat"]))
        s["vin"]  = 3.31
        s["acoustic"] = max(0.0, min(1.0, s["acoustic"] * (1 - alpha) + target_acoustic * alpha + random.gauss(0, 0.05)))

        return {
            "timestamp": time.time(),
            "pm1":       round(s["pm1"], 1),
            "pm25":      round(s["pm25"], 1),
            "pm10":      round(s["pm10"], 1),
            "co2":       s["co2"],
            "no2":       s["no2"],
            "co":        s["co"],
            "nh3":       0.45,
            "voc":       s["voc"],
            "tmp":       s["tmp"],
            "hum":       s["hum"],
            "prs":       s["prs"],
            "bat":       s["bat"],
            "vin":       s["vin"],
            "hlth":      s["hlth"],
            "acoustic":  round(s["acoustic"], 2)
        }
