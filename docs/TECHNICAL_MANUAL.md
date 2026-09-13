# 🛠️ AeroSense Edge: Technical & Deployment Manual

## 1. Hardware Architecture & Pinout Map

### Arduino UNO Q Pin Assignment
* **PMS5003 Laser Particulate**:
  * TX -> `D0` (RX on UNO Q)
  * RX -> `D1` (TX on UNO Q)
  * VCC -> `5.0V`, GND -> `GND`
* **Sensirion SCD41 / Bosch BME688 (I2C Bus)**:
  * SDA -> `D18` (A4)
  * SCL -> `D19` (A5)
  * VCC -> `3.3V`, GND -> `GND`
* **SGX MiCS-6814 Multi-Gas (Analog ADC)**:
  * NO2 Channel -> `A0`
  * CO Channel -> `A1`
  * NH3 Channel -> `A2`
  * VCC -> `5.0V` (Heater power), GND -> `GND`
* **Hardware Relay Actuators (GPIO)**:
  * Relay 1 (Exhaust Hood / Ventilation Fan) -> `D7`
  * Relay 2 (HEPA Purifier / Misting Sprinkler) -> `D8`
  * Relay 3 (Plant Siren / Safety Alarm) -> `D9`
* **Power Management / Battery Monitor**:
  * LiFePO4 Voltage Divider -> `A3`

---

## 2. Sensor Calibration Procedures

### A. Zero Baseline Drift Calibration (Clean Air Purge)
1. Place the assembled node in a clean air chamber (or outdoor rural baseline area with AQI < 25) for 30 minutes.
2. The firmware computes the baseline sensor resistance:
   $$R_{0,\text{NO2}} = R_{L} \times \frac{V_{ref} - V_{out}}{V_{out}}$$
3. Values are saved to non-volatile flash on the STM32U585 MCU.

### B. Humidity & Thermal Cross-Sensitivity Compensation
MOX gas sensors (MiCS-6814 and BME688) exhibit resistance variation with relative humidity. The feature pipeline compensates for ambient moisture using the polynomial compensation curve:
$$R_{comp} = R_{raw} \times \left(1.0 + 0.0045 \times (RH - 50.0) - 0.002 \times (T - 25.0)\right)$$

### C. Field Gain & Offset Calibration
Each sensor channel supports customizable gain ($a$) and zero-drift offset ($b$):
$$V_{calibrated} = a \cdot V_{raw} + b$$
Configurable via the **Anywhere Deployment Studio** or `POST /api/calibration`.

---

## 3. Universal "Anywhere" Deployment Profiles

AeroSense Edge can be deployed in 8 distinct environments with specialized operational rules and mathematical domain indices:

| Deployment Profile | Key Monitored Risks | Specialized Domain Index | Automated Relay Actuation |
| :--- | :--- | :--- | :--- |
| **🏫 Classroom / Office** | CO₂ drowsiness, study focus, stuffiness | **Cognitive Drowsiness Index (CDI)** (0–100 scale based on exhaled CO₂ and VOCs) | Relay 1: Fresh air damper opens when CO₂ > 1000 ppm |
| **🏥 Hospital / Cleanroom** | Aerosol viral pathogens, PM2.5 sterility | **Aerosol Infection Risk Index** (Wells-Riley surrogate based on CO₂, RH, and PM load) | Relay 2: Boosts terminal HEPA air cleaner when PM2.5 > 25 µg/m³ |
| **🏭 Industrial / Workshop** | Welding fumes, solvent vapors, toxic NO₂/CO | **OSHA/NIOSH 8-hr TWA Index** (% of legal occupational exposure ceiling) | Relay 1: Extraction dampers; Relay 3: Emergency siren if AQI > 180 |
| **🍳 Commercial Kitchen** | Frying oil aerosols, gas burner CO, VOCs | **Combustion Inefficiency Ratio** $(CO \times 1000) / CO_2$ | Relay 1: Range hood extractor auto-engages when VOC > 150 |
| **🌱 Smart Greenhouse** | Plant transpiration stress, mold/mildew | **Vapor Pressure Deficit (VPD)** ($VP_{sat} - VP_{act}$, optimal 0.8–1.4 kPa) | Relay 1: Circulation fans if VPD < 0.5; Relay 2: Fog misting if VPD > 1.4 |
| **🚇 Transit Hub / Metro** | Train brake friction dust (PM10), diesel soot | **Particulate Coarse Ratio** $PM_{2.5}/PM_{10} < 0.35$ | Relay 1: Tunnel axial jet fans engage when PM10 > 140 µg/m³ |
| **🏡 Residential / Home** | Sleep air quality, night quiet mode, dust | **WHO 24-hr Health Baseline Ratio** | Relay 2: Quiet bedroom HEPA purifier auto-trigger |
| **🌳 Campus / Smart City** | Perimeter traffic exhaust, garbage fires | **Stoichiometric Source Fingerprint** (95.4% calibrated classification) | Relay 2: Perimeter water mist cannons upon smoke detection |

---

## 4. International Multi-Standard AQI Calculation Engine

The station calculates sub-indices and composite air quality indices according to 4 regulatory standards:

1. **Indian NAQI (CPCB)**: 6 categories (Good, Satisfactory, Moderate, Poor, Very Poor, Severe) using standard Central Pollution Control Board piecewise breakpoints.
2. **US EPA AQI (Revised 2024)**: 6 categories (Good, Moderate, USG, Unhealthy, Very Unhealthy, Hazardous) with strict 9.0 µg/m³ annual PM2.5 baseline.
3. **European CAQI (EEA)**: 5 categories (Very Low, Low, Medium, High, Very High) on a normalized 0–100 urban scale.
4. **WHO 2021 Global Air Quality Guidelines**: Ratio calculation against strictest 24-hour targets (PM2.5 ≤ 15 µg/m³, PM10 ≤ 45 µg/m³, NO₂ ≤ 25 µg/m³).

Switch standard via `POST /api/standards` with `{"standard": "US_EPA"}` or in the Web Studio.

---

## 5. Smart Automation & Multi-Relay Rules Engine

Every second, live telemetry is evaluated against active profile rules:
* **Syntax**: `IF [metric] [operator] [threshold] THEN [action]`
* **Operators**: `>`, `>=`, `<`, `<=`, `==`, `!=`
* **Supported Actions**:
  * `relay_1`: Hardware Relay 1 (Exhaust Hood / Ventilation Fan)
  * `relay_2`: Hardware Relay 2 (HEPA Purifier / Misting Sprinklers)
  * `relay_3`: Hardware Relay 3 (Plant Siren / Safety Buzzer)
  * `relay_4`: Hardware Relay 4 (Automated HVAC Fresh-Air Auxiliary Damper)
  * `webhook`: HTTP POST alert payload to Slack, Discord, or Home Assistant

---

## 6. Zero-Dependency Pure-Python MQTT Publisher

AeroSense Edge includes a built-in, zero-dependency socket-based MQTT v3.1.1 publisher:
* **No external pip packages required** (pure standard library `socket` and `struct`).
* **Home Assistant MQTT Auto-Discovery**: Automatically broadcasts sensor discovery payloads to `homeassistant/sensor/aerosense_*/config` so that temperature, humidity, PM2.5, PM10, CO2, AQI, and attributed pollution source appear automatically in Home Assistant dashboards.
* **Telemetry Topic**: `<prefix>/telemetry` (default: `aerosense/telemetry`)
* **Configure**: via `POST /api/mqtt` or the Studio IoT panel.

---

## 7. Category-Defining Edge AI Innovations (v1.4.0)

### 7.1 Multi-Modal Acoustic Audio-FFT & Koschmieder Optical Extinction Haze
- **16-Band 1/3-Octave Acoustic Spectrum (31 Hz – 16 kHz)**: Differentiates low-frequency diesel engine rumble ($63\text{--}250\text{ Hz}$), mid-range machine hum ($500\text{--}1600\text{ Hz}$), and high-frequency culinary sizzle ($2\text{--}4\text{ kHz}$). Computes real-time spectral centroid in Hz.
- **Koschmieder Meteorological Extinction & Optical Haze**: Calculates visual range $V_R = \frac{3.912}{\beta_{ext}}$ in km, atmospheric contrast attenuation %, and Aerosol Optical Depth (AOD) surrogate without cloud cameras.

### 7.2 Hyperlocal Micro-Plume Gaussian Dispersion Vectoring
- Pinpoints emission origin compass bearing ($0^\circ\text{--}360^\circ$) and cardinal direction (e.g. $235^\circ\text{ WSW}$).
- Classifies upwind source distance category: *Immediate Proximity* ($<50\text{m}$), *Localized Zone* ($50\text{--}300\text{m}$), *Neighborhood Sector* ($300\text{m}\text{--}1\text{km}$), and *Regional Advection* ($>1\text{km}$).
- Solves Pasquill-Gifford lateral dispersion spread $\sigma_y(x) = c \cdot x^d$ to estimate physical plume footprint in meters.
- Triangulates peer node spatial gradients when wireless mesh neighbors are active; falls back to convective micro-flow modeling on isolated nodes.
- Formulates actionable municipal / RWA dispatch directives for security patrols.

### 7.3 Model Predictive Control (MPC) Smart Preemptive Actuation
- Evaluates 1–6 hour forward forecast horizon instead of simple reactive thresholding.
- Preemptively energizes HEPA purifiers or exhaust ventilation **15–30 minutes before** forecasted pollution surges arrive indoors, creating a clean pressurized air buffer.

### 7.4 On-Device Offline Conversational Voice Assistant ("AeroSense Voice")
- 100% local, air-gapped SLM reasoning running on Qualcomm QRB2210 Linux core with zero cloud dependency.
- Grounded in live stoichiometric chemistry, plume vectoring, and forecast horizons.
- Generates natural speech answers, immediate action recommendations, and Speech Synthesis Markup Language (SSML) for browser TTS playback.

### 7.5 Tamper-Proof Cryptographic SHA-256 Merkle Audit Ledger
- Computes pairwise Merkle tree reduction across individual sensor records and cryptographically links consecutive blocks with SHA-256 block hashes.
- Detects any manual database modification or tampering instantly.
- Exports cryptographic non-repudiation compliance certificates for regulatory filing (CPCB / US EPA / WHO).

---

## 8. REST API Reference

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/live` | Current live telemetry, stoichiometric ratios, plume vectoring, MPC status, and active profile |
| `GET` | `/api/plume` | Hyperlocal plume origin bearing, cardinal direction, distance, and dispatch directive |
| `GET` | `/api/audio-spectrum` | 16-band audio-FFT acoustic spectrum and Koschmieder optical extinction metrics |
| `GET` | `/api/mpc-status` | Model Predictive Control preemption state, lead time, and preemptive actions |
| `GET` | `/api/export/ledger` | Verify SHA-256 Merkle chain integrity and inspect historical environmental blocks |
| `GET` | `/api/export/certificate` | Export cryptographic regulatory compliance certificate (JSON) |
| `POST`| `/api/voice-query` | Query offline conversational voice assistant (`{"query": "Why does it smell like smoke?"}`) |
| `GET` | `/api/profiles` | List of 8 available environment profiles and currently active profile |
| `POST`| `/api/profiles` | Switch active environment profile (`{"profile": "Greenhouse"}`) |
| `GET` | `/api/standards` | List of 4 supported AQI standards and currently active standard |
| `POST`| `/api/standards` | Switch active AQI standard (`{"standard": "US_EPA"}`) |
| `GET` | `/api/calibration` | Read per-channel gain, offset, and enabled status |
| `POST`| `/api/calibration` | Save sensor channel gain and offset calibration |
| `GET` | `/api/rules` | Read active automation rules, webhook URL, and 4 relay states |
| `POST`| `/api/rules` | Add, delete, or toggle automation rules |
| `POST`| `/api/relay` | Manual hardware relay override (`{"relay_num": 1, "state": true}`) |
| `GET` | `/api/station` | Read station metadata (name, zone, coordinates) |
| `POST`| `/api/station` | Save station location and GPS coordinates |
| `GET` | `/api/mqtt` | Read MQTT publisher status and configuration |
| `POST`| `/api/mqtt` | Configure MQTT broker host, port, and topic prefix |
| `GET` | `/api/export/audit-report` | Export 24-hour compliance audit summary (JSON) |
| `GET` | `/api/export/csv` | Download raw SQLite telemetry history in CSV format |

