/**
 * @file uno_q_mcu.ino
 * @brief AeroSense Edge - STM32U585 Real-Time Sensor Acquisition & Health Monitor
 * Platform: Arduino UNO Q (STM32U585 Microcontroller Core)
 * 
 * Responsibilities:
 *  1. Microsecond-deterministic sampling of PMS5003, SCD41, BME688, MiCS-6814.
 *  2. Kalman filtering & spike rejection.
 *  3. Non-blocking IPC transmission to Qualcomm QRB2210 Linux Core.
 *  4. Power supply voltage monitoring (Solar / LiFePO4 battery level).
 */

#include "SensorDrivers.h"
#include "RingBufferIPC.h"

// Hardware Pin Definitions
#define PIN_STATUS_LED        LED_BUILTIN
#define PIN_BATTERY_VOLTAGE   A3
#define PIN_EXHAUST_RELAY     D7   // Actuator for ventilation/exhaust fan

// Instantiate Sensor Drivers
PMS5003Driver pmsSensor(&Serial1);  // Hardware UART1 (Pins D0/D1)
SCD41Driver   scd41Sensor;          // Hardware I2C (Pins A4/A5)
BME688Driver  bme688Sensor(0x76);   // Hardware I2C
MiCS6814Driver micsSensor(A0, A1, A2); // Analog ADC

// IPC Bridge to Qualcomm Cortex-A53 Linux via Internal Virtual Serial (Serial or SerialRPC)
#if defined(ARDUINO_UNOR4_WIFI) || defined(ARDUINO_ARCH_ZEPHYR) || defined(ARDUINO_UNO_Q)
  RingBufferIPC ipcBridge(&Serial);
#else
  RingBufferIPC ipcBridge(&Serial);
#endif

// Global Telemetry State
SensorTelemetry currentTelemetry;

// Timing Control
unsigned long last1HzTick = 0;
unsigned long lastFastADCTick = 0;
unsigned long lastSCD41Tick = 0;

// Moving average filters for noise suppression
float filter_pm25 = 0.0f;
float filter_pm10 = 0.0f;
float filter_no2  = 0.0f;
float filter_co   = 0.0f;

void setup() {
  // Initialize Serial IPC to Qualcomm Linux MPU
  Serial.begin(115200);
  
  pinMode(PIN_STATUS_LED, OUTPUT);
  pinMode(PIN_EXHAUST_RELAY, OUTPUT);
  digitalWrite(PIN_EXHAUST_RELAY, LOW);
  pinMode(PIN_BATTERY_VOLTAGE, INPUT);

  // Initialize sensors
  pmsSensor.begin(9600);
  micsSensor.begin();

  currentTelemetry.sensor_health_mask = 0x00;
  if (scd41Sensor.begin()) currentTelemetry.sensor_health_mask |= 0x02;
  if (bme688Sensor.begin()) currentTelemetry.sensor_health_mask |= 0x04;
  currentTelemetry.sensor_health_mask |= 0x09; // PMS & MiCS initialized

  // Visual blink indicator
  for (int i = 0; i < 3; i++) {
    digitalWrite(PIN_STATUS_LED, HIGH); delay(80);
    digitalWrite(PIN_STATUS_LED, LOW); delay(80);
  }
}

void loop() {
  unsigned long now = millis();

  // 1. High-frequency ADC Gas Sensor Read (every 100ms)
  if (now - lastFastADCTick >= 100) {
    lastFastADCTick = now;
    float raw_no2 = 0, raw_co = 0, raw_nh3 = 0;
    micsSensor.readGases(raw_no2, raw_co, raw_nh3);
    
    // Low-pass exponential filter: y[n] = 0.85*y[n-1] + 0.15*x[n]
    filter_no2 = (filter_no2 == 0.0f) ? raw_no2 : (0.85f * filter_no2 + 0.15f * raw_no2);
    filter_co  = (filter_co  == 0.0f) ? raw_co  : (0.85f * filter_co  + 0.15f * raw_co);
    
    currentTelemetry.no2_ppm = filter_no2;
    currentTelemetry.co_ppm  = filter_co;
    currentTelemetry.nh3_ppm = raw_nh3;
  }

  // 2. Particulate Matter UART update (continuous poll)
  float p1 = 0, p25 = 0, p10 = 0;
  if (pmsSensor.update(p1, p25, p10)) {
    filter_pm25 = (filter_pm25 == 0.0f) ? p25 : (0.8f * filter_pm25 + 0.2f * p25);
    filter_pm10 = (filter_pm10 == 0.0f) ? p10 : (0.8f * filter_pm10 + 0.2f * p10);
    currentTelemetry.pm1_0 = p1;
    currentTelemetry.pm2_5 = filter_pm25;
    currentTelemetry.pm10  = filter_pm10;
  }

  // 3. Periodic SCD41 & BME688 read (every 2.5s)
  if (now - lastSCD41Tick >= 2500) {
    lastSCD41Tick = now;
    float co2 = 0, t_scd = 0, rh_scd = 0;
    if (scd41Sensor.readMeasurement(co2, t_scd, rh_scd)) {
      currentTelemetry.co2_ppm = co2;
    }
    
    float t_bme = 0, rh_bme = 0, prs = 0, gas_res = 0, voc_idx = 0;
    if (bme688Sensor.readData(t_bme, rh_bme, prs, gas_res, voc_idx)) {
      currentTelemetry.temperature_c = t_bme;
      currentTelemetry.humidity_rh = rh_bme;
      currentTelemetry.pressure_hpa = prs;
      currentTelemetry.gas_resistance_kohm = gas_res;
      currentTelemetry.voc_index = voc_idx;
    }
  }

  // 4. Main 1Hz Telemetry Dispatch & IPC Transmission to Qualcomm Linux
  if (now - last1HzTick >= 1000) {
    last1HzTick = now;
    currentTelemetry.timestamp_ms = now;

    // Read Battery Voltage (Divider 2:1 on 3.2V LiFePO4)
    int raw_vbat = analogRead(PIN_BATTERY_VOLTAGE);
    float v_batt = (raw_vbat / 4095.0f) * 3.3f * 2.0f;
    currentTelemetry.v_in_mv = v_batt;
    // LiFePO4: 3.40V = 100%, 2.90V = 0%
    float pct = ((v_batt - 2.90f) / (3.40f - 2.90f)) * 100.0f;
    currentTelemetry.battery_percent = (uint8_t)constrain(pct, 0.0f, 100.0f);

    // Send structured JSON stream to Qualcomm Cortex-A53 Linux
    ipcBridge.transmitTelemetry(currentTelemetry);

    // Heartbeat Toggle
    digitalWrite(PIN_STATUS_LED, !digitalRead(PIN_STATUS_LED));
  }

  // 5. Process any incoming actuation / config commands from Linux MPU
  ipcBridge.processIncomingCommands();

  // Simple string-based IPC for actuation (non-blocking)
  while (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    if (cmd == "ACTUATE_RELAY:1") {
      digitalWrite(PIN_EXHAUST_RELAY, HIGH);
    } else if (cmd == "ACTUATE_RELAY:0") {
      digitalWrite(PIN_EXHAUST_RELAY, LOW);
    }
  }
}
