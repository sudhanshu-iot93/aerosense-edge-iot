# Hardware Wiring Schematics & Pinout Specification

## 1. Compute Platform: Arduino UNO Q Architecture
The **Arduino UNO Q** integrates a heterogeneous dual-compute system:
* **Application Processor (MPU)**: Qualcomm Dragonwing QRB2210 (Quad-Core ARM Cortex-A53 @ 1.3 GHz) running Debian Linux. Runs Edge AI inference, time-series forecasting, local SQLite database, and embedded web server.
* **Microcontroller (MCU)**: STM32U585 (ARM Cortex-M33 @ 160 MHz) with ultra-low power capabilities, deterministic sensor timing, and real-time hardware interfaces.
* **Inter-Core Bridge**: High-speed internal virtual UART / Shared Memory Ring Buffer connecting STM32 MCU to Qualcomm Linux MPU.

```
+-----------------------------------------------------------------------------------+
|                              ARDUINO UNO Q                                        |
|                                                                                   |
|  +-------------------------------------+  Internal IPC  +----------------------+  |
|  |       Qualcomm QRB2210 (MPU)        |<=============>|   STM32U585 (MCU)    |  |
|  |       Quad Cortex-A53 @ 1.3GHz      |  Virtual UART |  Cortex-M33 @ 160MHz |  |
|  |   Debian Linux + Edge AI Models     |   (115200+)   |  Deterministic Sense |  |
|  +-------------------------------------+               +----------------------+  |
|         |                  |                                      |               |
|    USB-C / Power      Wi-Fi / BLE                           Sensor Pins           |
+---------|------------------|--------------------------------------|---------------+
          |                  |                                      |
     Power Supply       Mesh & Sync                           Physical Sensors
 (5V 2A / Solar+BATT)  (Local P2P)                   (UART / I2C / ADC / Modulino)
```

---

## 2. Sensor Interfacing & Pin Mapping

| Sensor Module | Target Pollutant / Parameters | Interface | UNO Q Pin / Bus | Operating Voltage | Update Rate |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Plantower PMS5003** / **Sensirion SPS30** | $PM_{1.0}, PM_{2.5}, PM_{10}$ ($\mu g/m^3$) | UART (Serial1) | TX->D0 (RX), RX->D1 (TX) | 5.0V (Logic 3.3V) | 1 Hz |
| **Sensirion SCD41** | $CO_2$ (400-5000 ppm), Temp ($^\circ C$), RH (%) | I2C (Wire) | SDA->D18 (A4), SCL->D19 (A5) | 3.3V | 0.2 Hz (5s) |
| **Bosch BME688** | Gas Resistance ($\Omega$), VOC Index, Pressure, Temp, RH | I2C (Wire) | SDA->D18 (A4), SCL->D19 (A5) | 3.3V | 0.5 Hz (2s) |
| **SGX MiCS-6814** / **MQ135** | $NO_2, CO, NH_3$ (Oxidizing & Reducing Gases) | Analog (ADC) | $NO_2$->A0, $CO$->A1, $NH_3$->A2 | 5V Heater, 3.3V Vref | 10 Hz (Oversampled) |
| **Modulino Display / Screen** | Visual Status & Emergency Color Alert | I2C (Wire) | Modulino I2C Bus Connector | 3.3V | Event-driven |
| **Omni-Directional I2S Mic** (Optional) | Acoustic Traffic / Machinery Resonance | I2S | BCLK->D8, LRCLK->D9, DIN->D10 | 3.3V | 16 kHz Audio FFT |

---

## 3. Detailed Circuit Connection Table

### A. PMS5003 Laser Particulate Matter Sensor
* **Pin 1 (VCC)**: Connect to **5V** on UNO Q
* **Pin 2 (GND)**: Connect to **GND**
* **Pin 3 (SET)**: Pull-up to **3.3V** (Active High mode)
* **Pin 4 (RXD)**: Connect to **D1 (TX)** on UNO Q (3.3V Logic)
* **Pin 5 (TXD)**: Connect to **D0 (RX)** on UNO Q (3.3V Logic)
* **Pin 6 (RESET)**: Pull-up to **3.3V**

### B. Sensirion SCD41 NDIR CO2 Sensor
* **Pin 1 (VDD)**: Connect to **3.3V**
* **Pin 2 (GND)**: Connect to **GND**
* **Pin 3 (SCL)**: Connect to **SCL (A5)** with 4.7k$\Omega$ pull-up resistor
* **Pin 4 (SDA)**: Connect to **SDA (A4)** with 4.7k$\Omega$ pull-up resistor
* **I2C Address**: `0x62`

### C. Bosch BME688 Environmental & MOX VOC Sensor
* **Pin 1 (VCC)**: Connect to **3.3V**
* **Pin 2 (GND)**: Connect to **GND**
* **Pin 3 (SCL)**: Connect to **SCL (A5)**
* **Pin 4 (SDA)**: Connect to **SDA (A4)**
* **Pin 5 (SDO/ADDR)**: Connect to **GND** (I2C Address: `0x76`) or **3.3V** (`0x77`)

### D. MiCS-6814 Multi-Channel Gas Sensor
* **VCC**: Connect to **5V** (Heater supply)
* **GND**: Connect to **GND**
* **NOX Output (NO2 channel)**: Connect to **A0** (Voltage divider $R_L = 22k\Omega$ to GND)
* **RED Output (CO channel)**: Connect to **A1** (Voltage divider $R_L = 47k\Omega$ to GND)
* **NH3 Output (Ammonia/VOC channel)**: Connect to **A2** (Voltage divider $R_L = 47k\Omega$ to GND)

---

## 4. Signal Conditioning & Hardware Safety
1. **Low-Pass Filtering**: 0.1 $\mu F$ decoupling ceramic capacitors on all analog inputs (A0-A2) to eliminate RF noise from onboard Wi-Fi.
2. **Deterministic MCU Timing**: STM32U585 hardware timers trigger ADC conversions via DMA, eliminating any jitter caused by Linux CPU scheduling.
3. **Power Isolation**: Separate ground plane return for sensor heaters (MiCS-6814) to prevent analog ground bounce.
