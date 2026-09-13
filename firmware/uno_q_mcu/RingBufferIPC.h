/**
 * @file RingBufferIPC.h
 * @brief High-speed non-blocking IPC Bridge between STM32U585 MCU & Qualcomm QRB2210 Linux
 * @author AeroSense Edge Engineering Team
 */

#ifndef RING_BUFFER_IPC_H
#define RING_BUFFER_IPC_H

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>

#include "SensorDrivers.h"

#if defined(ARDUINO) || __has_include(<Arduino.h>)
  #include <Arduino.h>
#else
  class Stream {
  public:
    virtual int available() { return 0; }
    virtual int read() { return -1; }
    virtual void print(const char*) {}
    virtual void flush() {}
    virtual std::string readStringUntil(char) { return ""; }
  };
  #define String std::string
#endif

class RingBufferIPC {
private:
  Stream* _ipcStream;
  char _txBuffer[256];

public:
  RingBufferIPC(Stream* stream) : _ipcStream(stream) {}

  void begin() {
    // Initialization of IPC link
  }

  // Serialize telemetry into compact NDJSON (Newline Delimited JSON) for Linux MPU consumption
  void transmitTelemetry(const SensorTelemetry &data) {
    snprintf(_txBuffer, sizeof(_txBuffer),
      "{\"t\":%lu,\"pm1\":%.1f,\"pm25\":%.1f,\"pm10\":%.1f,\"co2\":%.1f,\"no2\":%.3f,\"co\":%.2f,\"nh3\":%.2f,\"voc\":%.1f,\"tmp\":%.2f,\"hum\":%.2f,\"prs\":%.1f,\"bat\":%u,\"vin\":%.2f,\"hlth\":%u}\n",
      (unsigned long)data.timestamp_ms,
      data.pm1_0,
      data.pm2_5,
      data.pm10,
      data.co2_ppm,
      data.no2_ppm,
      data.co_ppm,
      data.nh3_ppm,
      data.voc_index,
      data.temperature_c,
      data.humidity_rh,
      data.pressure_hpa,
      data.battery_percent,
      data.v_in_mv,
      data.sensor_health_mask
    );

    _ipcStream->print(_txBuffer);
    _ipcStream->flush();
  }

  // Receive commands from Linux MPU (e.g. calibration offsets, power state, fan control)
  bool processIncomingCommands() {
    if (_ipcStream->available()) {
      String cmd = _ipcStream->readStringUntil('\n');
      cmd.trim();
      if (cmd.startsWith("FAN:ON")) {
        // Handle fan actuation
        return true;
      } else if (cmd.startsWith("FAN:OFF")) {
        return true;
      } else if (cmd.startsWith("SLEEP:")) {
        // Adjust power mode
        return true;
      }
    }
    return false;
  }
};

#endif // RING_BUFFER_IPC_H
