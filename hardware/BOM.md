# Bill of Materials (BOM) & Economic Viability Analysis

## 1. Component Cost Breakdown (< $70 Target)

| Category | Component | Description / Specification | Unit Cost (USD) | Unit Cost (INR approx.) | Source / Manufacturer |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Compute Core** | Arduino UNO Q | Qualcomm QRB2210 (Quad Cortex-A53) + STM32U585 Dual-Compute Board | $38.00 | ₹3,150 | Arduino Official |
| **Particulate Sensor** | Plantower PMS5003 | Laser scattering PM1.0, PM2.5, PM10 (0.3μm - 10μm detection) | $14.50 | ₹1,200 | Plantower / Sensirion |
| **Gas Sensing Suite** | SGX MiCS-6814 | Triple MOS Gas Sensor (NO2, CO, NH3 / VOC detection) | $6.80 | ₹560 | SGX Sensortech |
| **Environmental** | Bosch BME688 / BME280 | Temperature, Humidity, Pressure, Gas Resistance (I2C) | $5.20 | ₹430 | Bosch Sensortec |
| **Power Supply** | TP5000 + 3.2V LiFePO4 Cell | 3.2V 3200mAh 18650 LiFePO4 (2000+ cycle life) + Charging BMS | $4.50 | ₹370 | Generic / EEMB |
| **Passives & Enclosure**| Weatherproof IP65 Box | UV-resistant 3D-printed / injection molded passive louvre case | $3.50 | ₹290 | Local Fab / Generic |
| **TOTAL BOM** | | **Complete Hyperlocal Edge AI Station** | **~$72.50** | **~₹6,000** | |

*(Optional NDIR Upgrade: Sensirion SCD41 photoacoustic CO2 sensor can be added for indoor classroom / kitchen nodes for +$18.00).*

---

## 2. Cost Comparison: Traditional Cloud Node vs. AeroSense Edge

| Metric | Traditional Cloud-Dependent Station | AeroSense Edge on Arduino UNO Q |
| :--- | :--- | :--- |
| **Hardware Capital Cost (CapEx)** | $250 - $1,200 | **~$72** |
| **Cloud API & Hosting Cost / Year (OpEx)**| $60 - $240 / station / year | **$0.00 / year (100% on-device AI)** |
| **Cellular Data Plan (Continuous raw streams)** | $120 / year (high telemetry) | **$0 - $10 / year (delta-compressed summaries)** |
| **Offline Reliability** | 0% (Blind during power cuts & outages) | **100% (Continuous AI inference & local storage)** |
| **Actionable Guidance & Attribution** | None (User sees raw number like "148 AQI") | **Instant Action Cards + Source Identification** |
| **5-Year Total Cost of Ownership (TCO)**| **$1,150 - $2,500** | **~$72 - $100 total** |

---

## 3. Scale Viability for Schools, RWAs & Municipalities
* **School Campus (5 Nodes)**: Total investment < ₹35,000 (~$420) covering classrooms, playground, canteen, gate.
* **Residential Colony / RWA (10 Nodes)**: Street-level pollution map across 1 km² for < ₹70,000 (~$840) with zero recurring maintenance fees.
