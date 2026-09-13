"""
mesh_node.py
============
Decentralized Multi-Node Mesh Protocol & Street-Level Spatial Interpolator.
Enables peer-to-peer air quality intelligence sharing across campuses,
colonies, or municipal wards without any per-node cloud subscription.
"""

import logging
import math
import time
from typing import Dict, Any, List

__all__ = ["MeshNode"]

logger = logging.getLogger(__name__)

# Peer is considered stale if no update within this many seconds
_STALE_TIMEOUT_S = 120


class MeshNode:
    def __init__(self, node_id: str = "NODE-01-MAIN", node_name: str = "Central Campus Gate",
                 lat: float = 20.3540, lon: float = 85.8180):
        self.node_id   = node_id
        self.node_name = node_name
        self.latitude  = lat
        self.longitude = lon
        self.peers: Dict[str, Dict[str, Any]] = {}
        self._init_default_campus_peers()
        logger.info("MeshNode initialized: %s (%s) at (%.4f, %.4f)", node_id, node_name, lat, lon)

    def _init_default_campus_peers(self):
        """Initializes simulated campus / ward peer nodes for mesh demonstration."""
        default_peers = [
            {
                "node_id":   "NODE-02-PLAYGROUND",
                "node_name": "East Sports Complex & Field",
                "lat":       self.latitude + 0.0025,
                "lon":       self.longitude + 0.0035,
                "distance_m":420,
                "pm25":      38.0,
                "pm10":      62.0,
                "aqi":       68,
                "source":    "Clean Baseline",
                "battery":   94,
                "status":    "ONLINE",
                "last_seen": time.time()
            },
            {
                "node_id":   "NODE-03-NORTH-GATE",
                "node_name": "North Gate Highway Arterial",
                "lat":       self.latitude + 0.0042,
                "lon":       self.longitude - 0.0018,
                "distance_m":580,
                "pm25":      142.0,
                "pm10":      185.0,
                "aqi":       195,
                "source":    "Traffic Exhaust",
                "battery":   88,
                "status":    "ONLINE",
                "last_seen": time.time()
            },
            {
                "node_id":   "NODE-04-CANTEEN",
                "node_name": "Dining & Kitchen Pavilion",
                "lat":       self.latitude - 0.0020,
                "lon":       self.longitude + 0.0015,
                "distance_m":260,
                "pm25":      78.0,
                "pm10":      95.0,
                "aqi":       115,
                "source":    "Cooking Smoke",
                "battery":   98,
                "status":    "ONLINE",
                "last_seen": time.time()
            },
            {
                "node_id":   "NODE-05-WEST-EXPANSION",
                "node_name": "West Construction Block",
                "lat":       self.latitude - 0.0035,
                "lon":       self.longitude - 0.0040,
                "distance_m":650,
                "pm25":      58.0,
                "pm10":      265.0,
                "aqi":       177,
                "source":    "Construction Dust",
                "battery":   76,
                "status":    "ONLINE",
                "last_seen": time.time()
            }
        ]

        for p in default_peers:
            self.peers[p["node_id"]] = p

    def update_local_reading(self, telemetry: Dict[str, Any], source_info: Dict[str, Any]):
        """Updates local node's telemetry broadcast state."""
        self.peers[self.node_id] = {
            "node_id":    self.node_id,
            "node_name":  self.node_name,
            "lat":        self.latitude,
            "lon":        self.longitude,
            "distance_m": 0,
            "pm25":       round(telemetry.get("pm25", 25.0), 1),
            "pm10":       round(telemetry.get("pm10", 45.0), 1),
            "aqi":        telemetry.get("aqi", 50),
            "source":     source_info.get("primary_source", "Clean Baseline"),
            "confidence": source_info.get("confidence_percent", 85),
            "battery":    telemetry.get("bat", 95),
            "status":     "LOCAL_MASTER",
            "last_seen":  time.time()
        }

    def receive_peer_update(self, peer_data: Dict[str, Any]):
        """Accepts a telemetry broadcast from another mesh node (P2P or gateway relay)."""
        nid = peer_data.get("node_id")
        if not nid:
            logger.warning("Received peer update without node_id; ignoring")
            return
        peer_data["last_seen"] = time.time()
        self.peers[nid] = peer_data
        logger.debug("Peer update received from %s: AQI=%d", nid, peer_data.get("aqi", -1))

    def get_mesh_topology(self) -> List[Dict[str, Any]]:
        """
        Returns list of all nodes in the decentralized mesh.
        Marks peers that haven't been seen recently as OFFLINE.
        """
        now    = time.time()
        result = []
        for node in self.peers.values():
            node_copy = dict(node)
            age = now - node_copy.get("last_seen", now)
            if node_copy.get("status") not in ("LOCAL_MASTER",) and age > _STALE_TIMEOUT_S:
                node_copy["status"] = "OFFLINE"
                logger.debug("Peer %s marked OFFLINE (last_seen %.0fs ago)", node_copy["node_id"], age)
            result.append(node_copy)
        return result

    def interpolate_spatial_aqi(self, target_lat: float, target_lon: float, power: float = 2.0) -> Dict[str, Any]:
        """
        Computes street-level hyperlocal AQI at any GPS coordinate using
        Inverse Distance Weighting (IDW) interpolation from mesh peers.
        """
        weights_sum   = 0.0
        weighted_aqi  = 0.0
        weighted_pm25 = 0.0

        online_peers = [n for n in self.peers.values() if n.get("status") != "OFFLINE"]

        for node in online_peers:
            d_lat = (node["lat"] - target_lat) * 111139.0        # metres
            d_lon = (node["lon"] - target_lon) * 111139.0 * math.cos(math.radians(target_lat))
            dist  = math.sqrt(d_lat**2 + d_lon**2)

            if dist < 5.0:  # Direct match
                return {
                    "interpolated_aqi":  node["aqi"],
                    "interpolated_pm25": node["pm25"],
                    "dominant_source":   node["source"],
                    "confidence":        1.0
                }

            w             = 1.0 / (dist ** power)
            weights_sum   += w
            weighted_aqi  += w * node["aqi"]
            weighted_pm25 += w * node["pm25"]

        if weights_sum == 0:
            return {"interpolated_aqi": 50, "interpolated_pm25": 25.0, "dominant_source": "Clean Baseline", "confidence": 0.5}

        final_aqi  = int(weighted_aqi  / weights_sum)
        final_pm25 = round(weighted_pm25 / weights_sum, 1)

        # Nearest online node determines primary source signature
        nearest_node = min(
            online_peers,
            key=lambda n: math.sqrt((n["lat"] - target_lat)**2 + (n["lon"] - target_lon)**2)
        )

        return {
            "interpolated_aqi":  final_aqi,
            "interpolated_pm25": final_pm25,
            "dominant_source":   nearest_node["source"],
            "nearest_node_id":   nearest_node["node_id"],
            "confidence":        0.88
        }
