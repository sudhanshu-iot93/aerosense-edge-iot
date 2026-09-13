# Power Management & Off-Grid Solar Specification

## 1. Power Budget Breakdown

| Component | Active Current (mA @ 5V) | Duty Cycle | Average Current (mA) | Daily Energy (mWh) |
| :--- | :--- | :--- | :--- | :--- |
| **Qualcomm QRB2210 Linux (Cortex-A53)** | 220 mA (Inference / Idle) | 100% | 180 mA | 21,600 mWh |
| **STM32U585 MCU (Real-time Sense)** | 12 mA | 100% | 12 mA | 1,440 mWh |
| **PMS5003 Laser Particulate** | 100 mA (Active Fan) | 30s every 2min (25%) | 25 mA | 3,000 mWh |
| **MiCS-6814 Gas Sensor Heaters** | 65 mA | 100% | 65 mA | 7,800 mWh |
| **SCD41 CO2 Sensor (NDIR)** | 18 mA (Measurement) | Periodic (10%) | 1.8 mA | 216 mWh |
| **BME688 MOX Environmental** | 3.9 mA | Periodic (20%) | 0.8 mA | 96 mWh |
| **Total Average Draw** | - | - | **~284.6 mA @ 5V (~1.42 W)** | **~34,152 mWh / day** |

---

## 2. Off-Grid Solar & Battery Sizing

* **Battery Chemistry**: **LiFePO4 (Lithium Iron Phosphate)**
  - Safe thermal threshold: -20°C to +65°C (no thermal runaway risk in direct sun).
  - Cycle life: 2,500+ cycles to 80% DoD (over 7 years daily cycling).
  - Nominal Voltage: 3.2V (Working Range: 2.8V - 3.65V).
* **Battery Capacity**: 2S or 1S2P 3.2V 6400mAh LiFePO4 pack (~20.5 Wh to 41 Wh).
  - Autonomous Runtime without Sun: **28 to 36 hours continuous full-speed operation**.
  - With dynamic MCU low-power sleep throttling: **Over 72 hours (3 continuous cloudy days)**.
* **Solar Panel Specification**:
  - 6V / 10W Monocrystalline Solar Panel with anti-reflective glass.
  - Generates ~40 Wh to 50 Wh per standard 5-sun-hour day in tropical/subtropical climates, providing a 140% daily energy surplus.
* **Charge Controller**:
  - TP5000 / CN3791 MPPT (Maximum Power Point Tracking) Solar LiFePO4 step-up/down regulator.
  - Hardware Under-Voltage Lockout (UVLO at 2.65V) to protect cells from deep discharge.

---

## 3. Power Cut & Outage Resilience Protocol
When grid/solar power is interrupted:
1. **STM32 Hardware Watchdog & Power Sensor**: Detects VIN drop below 4.75V.
2. **Graceful Linux Throttling**:
   - Reduces Cortex-A53 CPU frequency governor to `powersave` (600 MHz).
   - Increases AI inference period from 1 Hz to 10s intervals.
   - Fans PMS5003 laser for 15 seconds every 3 minutes instead of continuous spinning.
3. **Local Zero-Loss SQLite Logging**: Data is continuously committed to local eMMC/MicroSD; no cloud pinging attempts are made, preventing battery drain from repeated Wi-Fi beacon timeouts.
