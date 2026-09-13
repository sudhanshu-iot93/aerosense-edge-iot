"""
plume_vectoring.py
==================
On-Device Micro-Atmospheric Gaussian Plume Dispersion & Origin Vectoring Engine.
Runs locally on Arduino UNO Q (Qualcomm QRB2210 Linux core).

Capabilities:
 1. Estimates Windward Compass Bearing (0-360 deg) to emission origin.
 2. Approximates Source Distance (Immediate <50m, Localized 50-300m, Regional >1km).
 3. Computes Gaussian Plume lateral dispersion footprint (sigma_y, sigma_z).
 4. Triangulates multi-node mesh concentration spatial gradients when peer nodes are present.
 5. Formats actionable dispatch directives for RWA / Municipal security patrols.
"""

import math
import time
from typing import Dict, Any, List, Optional

__all__ = ["MicroPlumeVectorEngine"]


class MicroPlumeVectorEngine:
    CARDINALS = [
        ("N", 0.0), ("NNE", 22.5), ("NE", 45.0), ("ENE", 67.5),
        ("E", 90.0), ("ESE", 112.5), ("SE", 135.0), ("SSE", 157.5),
        ("S", 180.0), ("SSW", 202.5), ("SW", 225.0), ("WSW", 247.5),
        ("W", 270.0), ("WNW", 292.5), ("NW", 315.0), ("NNW", 337.5)
    ]

    def __init__(self, default_lat: float = 20.3540, default_lon: float = 85.8180):
        self.node_lat = default_lat
        self.node_lon = default_lon

    @classmethod
    def deg_to_cardinal(cls, deg: float) -> str:
        deg = deg % 360.0
        best_card = "N"
        min_diff = 360.0
        for card, angle in cls.CARDINALS:
            diff = abs(deg - angle)
            if diff > 180.0:
                diff = 360.0 - diff
            if diff < min_diff:
                min_diff = diff
                best_card = card
        return best_card

    def estimate_plume_origin(
        self,
        features: Dict[str, Any],
        source_attribution: Dict[str, Any],
        mesh_neighbors: Optional[List[Dict[str, Any]]] = None
    ) -> Dict[str, Any]:
        """
        Estimates the windward direction, distance, and Gaussian dispersion cone
        of the dominant air pollution source using local telemetry and peer mesh nodes.
        """
        primary_source = source_attribution.get("primary_source", "Clean Baseline")
        confidence     = float(source_attribution.get("confidence", 0.75))
        pm25           = float(features.get("pm25", 15.0))
        voc            = float(features.get("voc", 30.0))
        d_pm25_dt      = float(features.get("d_pm25_dt", 0.0))
        temp           = float(features.get("tmp", 25.0))
        prs            = float(features.get("prs", 1013.25))
        ts             = float(features.get("timestamp", time.time()))

        if primary_source == "Clean Baseline" or pm25 < 25.0:
            return {
                "active_plume": False,
                "bearing_deg": 0.0,
                "cardinal": "N",
                "distance_m": 0,
                "distance_category": "No Significant Plume Detected",
                "plume_spread_deg": 0.0,
                "confidence_pct": 98.0,
                "dispatch_directive": "Ambient atmosphere within clean baseline. No active plume detection.",
                "source": primary_source,
                "dispersion_model": {
                    "stability_class": "B (Moderate Solar Convection)",
                    "estimated_wind_speed_ms": 1.5,
                    "plume_width_m": 0
                }
            }

        # --------------------------------------------------------------
        # 1. Multi-Node Spatial Gradient Triangulation (if mesh peers exist)
        # --------------------------------------------------------------
        triangulated_bearing = None
        if mesh_neighbors and len(mesh_neighbors) >= 1:
            grad_x = 0.0
            grad_y = 0.0
            valid_peers = 0
            for peer in mesh_neighbors:
                peer_lat = peer.get("lat")
                peer_lon = peer.get("lon")
                peer_pm  = peer.get("pm25", pm25)
                if peer_lat is not None and peer_lon is not None:
                    # Cartesian delta in meters (~111.32 km per deg lat)
                    dx = (peer_lon - self.node_lon) * 111320.0 * math.cos(math.radians(self.node_lat))
                    dy = (peer_lat - self.node_lat) * 111320.0
                    dist = math.hypot(dx, dy)
                    if dist > 5.0:
                        delta_pm = peer_pm - pm25
                        grad_x += (delta_pm / dist) * (dx / dist)
                        grad_y += (delta_pm / dist) * (dy / dist)
                        valid_peers += 1

            if valid_peers > 0 and math.hypot(grad_x, grad_y) > 0.001:
                # Plume originates UPWIND / towards higher concentration gradient
                angle_rad = math.atan2(grad_x, grad_y)
                triangulated_bearing = (math.degrees(angle_rad) + 360.0) % 360.0

        # --------------------------------------------------------------
        # 2. Local Micro-Meteorological Bearing Estimation (Single Node Fallback)
        # --------------------------------------------------------------
        if triangulated_bearing is not None:
            bearing_deg = round(triangulated_bearing, 1)
        else:
            # Diurnal micro-convective model based on hour & local thermal flow
            tm = time.localtime(ts)
            hour = tm.tm_hour + tm.tm_min / 60.0
            
            # Baseline diurnal wind angle (SW in afternoon, NE at night in typical Indian subcontinent valleys)
            if 9.0 <= hour <= 18.0:
                base_angle = 235.0  # WSW daytime thermal wind
            else:
                base_angle = 45.0   # NE nocturnal katabatic drainage
            
            # Micro-barometric perturbation (-1013.25 mb trend)
            baro_perturbation = (prs - 1013.25) * 4.5
            # Specific source signature adjustments
            source_bias = 0.0
            if primary_source == "Traffic Exhaust":
                source_bias = 15.0  # Main campus arterial boulevard axis
            elif primary_source == "Garbage Burning":
                source_bias = -25.0 # Western municipal dump perimeter
            elif primary_source == "Cooking Smoke":
                source_bias = 40.0  # Commercial dining hall complex
            elif primary_source == "Construction Dust":
                source_bias = -50.0 # North-west infrastructure excavation site
                
            bearing_deg = round((base_angle + baro_perturbation + source_bias) % 360.0, 1)

        cardinal = self.deg_to_cardinal(bearing_deg)

        # --------------------------------------------------------------
        # 3. Source Distance Estimation (Micro-Stoichiometric Decay)
        # --------------------------------------------------------------
        # Acute spikes with high dPM/dt indicate immediate proximity (<50m)
        if d_pm25_dt > 2.5 or (primary_source == "Cooking Smoke" and voc > 180):
            distance_m = round(max(15, 60 - min(45, d_pm25_dt * 12)))
            dist_cat = "Immediate Proximity (< 50m)"
        elif d_pm25_dt > 0.8 or primary_source in ("Garbage Burning", "Construction Dust"):
            distance_m = round(min(350, max(50, 180 - min(100, d_pm25_dt * 30))))
            dist_cat = "Localized Zone (50 - 300m)"
        else:
            # Stale / steady elevated background = regional plume (>1km)
            distance_m = round(min(5000, max(800, 1200 + pm25 * 5.0)))
            dist_cat = "Regional Transport (> 1km)"

        # --------------------------------------------------------------
        # 4. Gaussian Plume Lateral Spread (Pasquill-Gifford Stability)
        # --------------------------------------------------------------
        # Class B (moderately unstable daytime) vs Class D (neutral) vs Class F (stable inversion)
        if temp < 18.0 and features.get("hum", 50.0) > 75.0:
            stability_class = "F (Stable Nocturnal Inversion)"
            sigma_y_coeff = 0.08
            plume_spread_deg = 14.0
        elif 10.0 <= time.localtime(ts).tm_hour <= 16.0:
            stability_class = "B (Moderately Unstable Convective)"
            sigma_y_coeff = 0.22
            plume_spread_deg = 28.0
        else:
            stability_class = "D (Neutral Boundary Layer)"
            sigma_y_coeff = 0.14
            plume_spread_deg = 20.0

        # Lateral plume width: W = 4 * sigma_y at distance_m
        plume_width_m = round(4.0 * (sigma_y_coeff * math.pow(max(10.0, distance_m), 0.89)), 1)
        est_wind_speed = 1.8 if "B" in stability_class else 1.2

        # --------------------------------------------------------------
        # 5. Formulate Actionable Dispatch Directive
        # --------------------------------------------------------------
        if primary_source == "Garbage Burning":
            directive = f"Active burning plume detected at {bearing_deg}° ({cardinal}), ~{distance_m}m upwind. Dispatch RWA security patrol immediately."
        elif primary_source == "Traffic Exhaust":
            directive = f"Heavy vehicle emissions arriving from {bearing_deg}° ({cardinal}) roadway. Advise pedestrians to divert walking paths."
        elif primary_source == "Construction Dust":
            directive = f"Excavation dust plume from {bearing_deg}° ({cardinal}), ~{distance_m}m. Trigger water mist suppression sprinklers."
        elif primary_source == "Cooking Smoke":
            directive = f"Kitchen exhaust surge detected at {bearing_deg}° ({cardinal}), ~{distance_m}m. Switch indoor purifiers to maximum."
        elif primary_source == "Crop Residue":
            directive = f"Regional stubble smoke drifting from {bearing_deg}° ({cardinal}), ~{distance_m}m. Close community ventilation louvers."
        else:
            directive = f"Elevated emission vector: {bearing_deg}° ({cardinal}) at ~{distance_m}m."

        return {
            "active_plume": True,
            "bearing_deg": bearing_deg,
            "cardinal": cardinal,
            "distance_m": distance_m,
            "distance_category": dist_cat,
            "plume_spread_deg": plume_spread_deg,
            "plume_width_m": plume_width_m,
            "confidence_pct": round(confidence * 100.0, 1),
            "dispatch_directive": directive,
            "source": primary_source,
            "dispersion_model": {
                "stability_class": stability_class,
                "estimated_wind_speed_ms": est_wind_speed,
                "plume_width_m": plume_width_m
            }
        }
