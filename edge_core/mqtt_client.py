"""
mqtt_client.py
==============
Pure-Python, Zero-Dependency MQTT v3.1.1 Publisher for Arduino UNO Q.
Enables plug-and-play IoT integration with Home Assistant, Mosquitto,
ThingsBoard, Node-RED, and Grafana with zero external pip dependencies.
"""

import json
import logging
import socket
import struct
import threading
import time
from typing import Dict, Any, Optional

__all__ = ["MQTTPublisher"]

logger = logging.getLogger(__name__)


class MQTTPublisher:
    def __init__(self, host: str = "localhost", port: int = 1883,
                 client_id: str = "AeroSense-UNO-Q", topic_prefix: str = "aerosense",
                 enabled: bool = False):
        self.host         = host
        self.port         = port
        self.client_id    = client_id
        self.topic_prefix = topic_prefix.rstrip("/")
        self.enabled      = enabled
        self.sock: Optional[socket.socket] = None
        self.connected    = False
        self.lock         = threading.Lock()
        self._last_conn_try = 0

    def configure(self, host: str, port: int = 1883, topic_prefix: str = "aerosense", enabled: bool = True):
        with self.lock:
            self.host         = host.strip()
            self.port         = int(port)
            self.topic_prefix = topic_prefix.strip().rstrip("/")
            self.enabled      = enabled
            self._disconnect()
        logger.info("MQTT configuration updated: %s:%d (enabled=%s)", self.host, self.port, self.enabled)

    def _disconnect(self):
        if self.sock:
            try:
                # MQTT DISCONNECT packet: 0xE0 0x00
                self.sock.send(b"\xe0\x00")
                self.sock.close()
            except Exception:
                pass
            self.sock = None
        self.connected = False

    def _connect(self) -> bool:
        if not self.enabled or not self.host:
            return False
        now = time.time()
        if now - self._last_conn_try < 15:  # Rate-limit reconnection attempts
            return False
        self._last_conn_try = now

        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(3.0)
            s.connect((self.host, self.port))

            # Encode MQTT v3.1.1 CONNECT packet
            proto_name = b"MQTT"
            proto_level = 4
            connect_flags = 0x02  # Clean session
            keepalive = 60

            payload = bytearray()
            # Client ID
            cid_bytes = self.client_id.encode("utf-8")
            payload.extend(struct.pack(">H", len(cid_bytes)))
            payload.extend(cid_bytes)

            var_header = bytearray()
            var_header.extend(struct.pack(">H", len(proto_name)))
            var_header.extend(proto_name)
            var_header.append(proto_level)
            var_header.append(connect_flags)
            var_header.extend(struct.pack(">H", keepalive))

            rem_len = len(var_header) + len(payload)
            packet = bytearray([0x10])  # CONNECT
            packet.extend(self._encode_remaining_length(rem_len))
            packet.extend(var_header)
            packet.extend(payload)

            s.sendall(packet)

            # Read CONNACK (4 bytes: 0x20, 0x02, ack_flags, return_code)
            resp = s.recv(4)
            if len(resp) >= 4 and resp[0] == 0x20 and resp[3] == 0x00:
                self.sock = s
                self.connected = True
                logger.info("Connected to MQTT broker at %s:%d", self.host, self.port)
                # Publish Home Assistant auto-discovery
                self._publish_ha_discovery()
                return True
            else:
                s.close()
                return False
        except Exception as exc:
            logger.debug("MQTT broker connection failed (%s:%d): %s", self.host, self.port, exc)
            self.connected = False
            return False

    @staticmethod
    def _encode_remaining_length(length: int) -> bytearray:
        encoded = bytearray()
        while True:
            digit = length % 128
            length = length // 128
            if length > 0:
                digit |= 0x80
            encoded.append(digit)
            if length == 0:
                break
        return encoded

    def publish(self, topic_suffix: str, payload_str: str) -> bool:
        if not self.enabled:
            return False

        with self.lock:
            if not self.connected:
                if not self._connect():
                    return False

            topic = f"{self.topic_prefix}/{topic_suffix}"
            try:
                topic_bytes = topic.encode("utf-8")
                payload_bytes = payload_str.encode("utf-8")

                var_header = bytearray()
                var_header.extend(struct.pack(">H", len(topic_bytes)))
                var_header.extend(topic_bytes)

                rem_len = len(var_header) + len(payload_bytes)
                packet = bytearray([0x30])  # PUBLISH, QoS 0
                packet.extend(self._encode_remaining_length(rem_len))
                packet.extend(var_header)
                packet.extend(payload_bytes)

                self.sock.sendall(packet)
                return True
            except Exception as exc:
                logger.debug("MQTT publish failed: %s", exc)
                self._disconnect()
                return False

    def publish_telemetry(self, features: Dict[str, Any], source_info: Dict[str, Any]):
        """Publish full sensor telemetry and source state to MQTT."""
        if not self.enabled:
            return
        payload = {
            "aqi":            features.get("aqi", 0),
            "aqi_category":   features.get("aqi_category", ""),
            "primary_source": source_info.get("primary_source", ""),
            "confidence":     source_info.get("confidence_percent", 0),
            "pm1":            features.get("pm1", 0.0),
            "pm25":           features.get("pm25", 0.0),
            "pm10":           features.get("pm10", 0.0),
            "co2":            features.get("co2", 0.0),
            "no2":            features.get("no2", 0.0),
            "co":             features.get("co", 0.0),
            "voc":            features.get("voc", 0.0),
            "temp":           features.get("tmp", 0.0),
            "hum":            features.get("hum", 0.0),
            "vpd_kpa":        features.get("vpd", {}).get("vpd_kpa", 0.0),
            "timestamp":      int(time.time())
        }
        self.publish("telemetry", json.dumps(payload))

    def _publish_ha_discovery(self):
        """Home Assistant MQTT Auto-Discovery configuration topics."""
        sensors = [
            ("aqi",  "Air Quality Index", "aqi", None, "{{ value_json.aqi }}"),
            ("pm25", "Particulate PM2.5", "pm25", "µg/m³", "{{ value_json.pm25 }}"),
            ("pm10", "Particulate PM10",  "pm10", "µg/m³", "{{ value_json.pm10 }}"),
            ("co2",  "Carbon Dioxide",    "carbon_dioxide", "ppm", "{{ value_json.co2 }}"),
            ("temp", "Temperature",       "temperature", "°C", "{{ value_json.temp }}"),
            ("hum",  "Humidity",          "humidity", "%", "{{ value_json.hum }}"),
            ("source", "Attributed Source", None, None, "{{ value_json.primary_source }}")
        ]
        for s_id, s_name, dev_class, unit, val_tpl in sensors:
            disc_topic = f"homeassistant/sensor/aerosense_{s_id}/config"
            cfg = {
                "name": f"AeroSense {s_name}",
                "state_topic": f"{self.topic_prefix}/telemetry",
                "value_template": val_tpl,
                "unique_id": f"aerosense_uno_q_{s_id}",
                "device": {
                    "identifiers": ["aerosense_uno_q_station"],
                    "name": "AeroSense Pro Edge Station",
                    "model": "Arduino UNO Q (QRB2210 + STM32U585)",
                    "manufacturer": "AeroSense Edge AI"
                }
            }
            if dev_class:
                cfg["device_class"] = dev_class
            if unit:
                cfg["unit_of_measurement"] = unit

            # Publish config with retain-like single burst
            self.publish(f"discovery/{s_id}", json.dumps(cfg))

    def get_status(self) -> Dict[str, Any]:
        return {
            "enabled": self.enabled,
            "host": self.host,
            "broker": self.host,
            "port": self.port,
            "topic_prefix": self.topic_prefix,
            "connected": self.connected
        }
