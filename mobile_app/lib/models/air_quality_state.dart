// models/air_quality_state.dart

class TelemetryData {
  final double pm1;
  final double pm25;
  final double pm10;
  final double no2;
  final double co;
  final double co2;
  final double voc;
  final double temp;
  final double humidity;
  final double pressure;
  final int battery;
  final double vin;
  final bool isCharging;
  final int timestamp;

  TelemetryData({
    required this.pm1,
    required this.pm25,
    required this.pm10,
    required this.no2,
    required this.co,
    required this.co2,
    required this.voc,
    required this.temp,
    required this.humidity,
    required this.pressure,
    required this.battery,
    required this.vin,
    required this.isCharging,
    required this.timestamp,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      pm1: (json['pm1'] as num?)?.toDouble() ?? 10.0,
      pm25: (json['pm25'] as num?)?.toDouble() ?? 15.0,
      pm10: (json['pm10'] as num?)?.toDouble() ?? 25.0,
      no2: (json['no2'] as num?)?.toDouble() ?? 0.02,
      co: (json['co'] as num?)?.toDouble() ?? 0.5,
      co2: (json['co2'] as num?)?.toDouble() ?? 420.0,
      voc: (json['voc'] as num?)?.toDouble() ?? 30.0,
      temp: (json['tmp'] as num?)?.toDouble() ?? 26.0,
      humidity: (json['hum'] as num?)?.toDouble() ?? 50.0,
      pressure: (json['prs'] as num?)?.toDouble() ?? 1013.25,
      battery: (json['bat'] as num?)?.toInt() ?? 96,
      vin: (json['vin'] as num?)?.toDouble() ?? 3.32,
      isCharging: json['charging'] as bool? ?? true,
      timestamp: (json['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Map<String, dynamic> toJson() => {
    'pm1': pm1,
    'pm25': pm25,
    'pm10': pm10,
    'no2': no2,
    'co': co,
    'co2': co2,
    'voc': voc,
    'tmp': temp,
    'hum': humidity,
    'prs': pressure,
    'bat': battery,
    'vin': vin,
    'charging': isCharging,
    'timestamp': timestamp,
  };
}

class FeaturesData {
  final double pmRatio;
  final double coToCo2Ratio;
  final double no2ToVocRatio;
  final int aqi;
  final String aqiCategory;
  final String primaryPollutant;

  FeaturesData({
    required this.pmRatio,
    required this.coToCo2Ratio,
    required this.no2ToVocRatio,
    required this.aqi,
    required this.aqiCategory,
    required this.primaryPollutant,
  });

  factory FeaturesData.fromJson(Map<String, dynamic> json) {
    return FeaturesData(
      pmRatio: (json['pm_ratio'] as num?)?.toDouble() ?? 0.5,
      coToCo2Ratio: (json['co_to_co2_ratio'] as num?)?.toDouble() ?? 1.0,
      no2ToVocRatio: (json['no2_to_voc_ratio'] as num?)?.toDouble() ?? 0.6,
      aqi: (json['aqi'] as num?)?.toInt() ?? 42,
      aqiCategory: json['aqi_category'] as String? ?? 'Good',
      primaryPollutant: json['primary_pollutant'] as String? ?? 'PM2.5',
    );
  }
}

class AttributionFactor {
  final String factor;
  final String evidence;

  AttributionFactor({required this.factor, required this.evidence});

  factory AttributionFactor.fromJson(Map<String, dynamic> json) {
    return AttributionFactor(
      factor: json['factor'] as String? ?? '',
      evidence: json['evidence'] as String? ?? '',
    );
  }
}

class AiBenchmark {
  final double inferenceTimeMs;
  final int memoryFootprintKb;
  final String modelArchitecture;
  final String quantization;
  final String targetPlatform;

  AiBenchmark({
    required this.inferenceTimeMs,
    required this.memoryFootprintKb,
    required this.modelArchitecture,
    required this.quantization,
    required this.targetPlatform,
  });

  factory AiBenchmark.fromJson(Map<String, dynamic> json) {
    return AiBenchmark(
      inferenceTimeMs: (json['inference_time_ms'] as num?)?.toDouble() ?? 0.82,
      memoryFootprintKb: (json['memory_footprint_kb'] as num?)?.toInt() ?? 112,
      modelArchitecture: json['model_architecture'] as String? ?? 'Stoichiometric Gradient Fusion',
      quantization: json['quantization'] as String? ?? 'INT8 Fixed Precision Calibrated',
      targetPlatform: json['target_platform'] as String? ?? 'Arduino UNO Q (Qualcomm QRB2210)',
    );
  }
}

class SourceAttribution {
  final String primarySource;
  final int confidencePercent;
  final String description;
  final List<AttributionFactor> attributions;
  final AiBenchmark aiBenchmark;

  SourceAttribution({
    required this.primarySource,
    required this.confidencePercent,
    required this.description,
    required this.attributions,
    required this.aiBenchmark,
  });

  factory SourceAttribution.fromJson(Map<String, dynamic> json) {
    final rawList = json['attributions'] as List<dynamic>? ?? [];
    final rawBm = json['ai_benchmark'] as Map<String, dynamic>? ?? {};
    return SourceAttribution(
      primarySource: json['primary_source'] as String? ?? 'Clean Baseline',
      confidencePercent: (json['confidence_percent'] as num?)?.toInt() ?? 92,
      description: json['description'] as String? ?? 'Natural ambient background with normal trace gases.',
      attributions: rawList
          .map((item) => AttributionFactor.fromJson(item as Map<String, dynamic>))
          .toList(),
      aiBenchmark: AiBenchmark.fromJson(rawBm),
    );
  }
}

class ForecastHorizon {
  final String label;
  final String targetTimeStr;
  final double predictedPm25;
  final int predictedAqi;

  ForecastHorizon({
    required this.label,
    required this.targetTimeStr,
    required this.predictedPm25,
    required this.predictedAqi,
  });

  factory ForecastHorizon.fromJson(Map<String, dynamic> json) {
    return ForecastHorizon(
      label: json['label'] as String? ?? '+1h',
      targetTimeStr: json['target_time_str'] as String? ?? '--:--',
      predictedPm25: double.tryParse(json['predicted_pm25']?.toString() ?? '15.0') ?? 15.0,
      predictedAqi: (json['predicted_aqi'] as num?)?.toInt() ?? 40,
    );
  }
}

class ForecastData {
  final String overallTrend;
  final List<ForecastHorizon> forecastHorizons;
  final String diurnalTip;

  ForecastData({
    required this.overallTrend,
    required this.forecastHorizons,
    required this.diurnalTip,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    final rawHorizons = json['forecast_horizons'] as List<dynamic>? ?? [];
    return ForecastData(
      overallTrend: json['overall_trend'] as String? ?? 'STABLE',
      forecastHorizons: rawHorizons
          .map((item) => ForecastHorizon.fromJson(item as Map<String, dynamic>))
          .toList(),
      diurnalTip: json['diurnal_tip'] as String? ??
          'Best natural ventilation window: 13:00 - 16:00 during solar atmospheric boundary lifting.',
    );
  }
}

class ActionItem {
  final String title;
  final String subtitle;
  final String? icon;
  final String? priority;

  ActionItem({
    required this.title,
    required this.subtitle,
    this.icon,
    this.priority,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      title: json['action'] as String? ?? json['role'] as String? ?? json['entity'] as String? ?? '',
      subtitle: json['timing'] as String? ?? json['recommendation'] as String? ?? json['action'] as String? ?? '',
      icon: json['icon'] as String?,
      priority: json['priority'] as String?,
    );
  }
}

class AdvisoryData {
  final String headline;
  final List<String> urgentAlerts;
  final List<ActionItem> citizenActions;
  final List<ActionItem> schoolActions;
  final List<ActionItem> communityActions;

  AdvisoryData({
    required this.headline,
    required this.urgentAlerts,
    required this.citizenActions,
    required this.schoolActions,
    required this.communityActions,
  });

  factory AdvisoryData.fromJson(Map<String, dynamic> json) {
    final rawUrgent = json['urgent_alerts'] as List<dynamic>? ?? [];
    final rawCitizen = json['citizen_actions'] as List<dynamic>? ?? [];
    final rawSchool = json['school_actions'] as List<dynamic>? ?? [];
    final rawCommunity = json['community_actions'] as List<dynamic>? ?? [];

    return AdvisoryData(
      headline: json['headline'] as String? ?? 'Air quality is within normal parameters.',
      urgentAlerts: rawUrgent.map((e) => e.toString()).toList(),
      citizenActions: rawCitizen.map((e) => ActionItem.fromJson(e as Map<String, dynamic>)).toList(),
      schoolActions: rawSchool.map((e) => ActionItem.fromJson(e as Map<String, dynamic>)).toList(),
      communityActions: rawCommunity.map((e) => ActionItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class MeshNodeInfo {
  final String nodeId;
  final String nodeName;
  final double lat;
  final double lon;
  final int aqi;
  final String source;
  final int battery;

  MeshNodeInfo({
    required this.nodeId,
    required this.nodeName,
    required this.lat,
    required this.lon,
    required this.aqi,
    required this.source,
    required this.battery,
  });

  factory MeshNodeInfo.fromJson(Map<String, dynamic> json) {
    return MeshNodeInfo(
      nodeId: json['node_id'] as String? ?? 'UNKNOWN',
      nodeName: json['node_name'] as String? ?? 'Mesh Node',
      lat: (json['lat'] as num?)?.toDouble() ?? 20.3540,
      lon: (json['lon'] as num?)?.toDouble() ?? 85.8180,
      aqi: (json['aqi'] as num?)?.toInt() ?? 50,
      source: json['source'] as String? ?? 'Clean Baseline',
      battery: (json['battery'] as num?)?.toInt() ?? 90,
    );
  }
}

class CompressionStats {
  final int rawBytes;
  final int compressedBytes;
  final double bandwidthSavingsPct;
  final String hexSample;

  CompressionStats({
    required this.rawBytes,
    required this.compressedBytes,
    required this.bandwidthSavingsPct,
    required this.hexSample,
  });

  factory CompressionStats.fromJson(Map<String, dynamic> json, {String hexSample = ''}) {
    return CompressionStats(
      rawBytes: (json['raw_bytes'] as num?)?.toInt() ?? 12800,
      compressedBytes: (json['compressed_bytes'] as num?)?.toInt() ?? 1357,
      bandwidthSavingsPct: (json['bandwidth_savings_pct'] as num?)?.toDouble() ?? 89.4,
      hexSample: hexSample,
    );
  }
}

class SystemInfo {
  final String hardware;
  final String mpu;
  final String mcu;
  final String os;
  final String aiEngine;
  final String cloudDependency;
  final int uptimeSeconds;

  SystemInfo({
    required this.hardware,
    required this.mpu,
    required this.mcu,
    required this.os,
    required this.aiEngine,
    required this.cloudDependency,
    required this.uptimeSeconds,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) {
    return SystemInfo(
      hardware: json['hardware'] as String? ?? 'Arduino UNO Q',
      mpu: json['mpu'] as String? ?? 'Qualcomm QRB2210 Quad Cortex-A53 @ 1.3GHz',
      mcu: json['mcu'] as String? ?? 'STM32U585 Cortex-M33 @ 160MHz',
      os: json['os'] as String? ?? 'Debian Linux (Embedded Edge)',
      aiEngine: json['ai_engine'] as String? ?? 'Quantized Edge AI (TFLite / ONNX Ready)',
      cloudDependency: json['cloud_dependency'] as String? ?? '0% (Fully Autonomous Offline)',
      uptimeSeconds: (json['uptime_seconds'] as num?)?.toInt() ?? 0,
    );
  }
}

class AeroSenseState {
  final TelemetryData telemetry;
  final FeaturesData features;
  final SourceAttribution sourceAttribution;
  final ForecastData forecast;
  final AdvisoryData advisory;
  final List<MeshNodeInfo> meshTopology;
  final CompressionStats compressionStats;
  final SystemInfo systemInfo;
  final bool isLiveConnected;
  final String activeScenario;
  final String activeProfile;
  final String activeStandard;

  AeroSenseState({
    required this.telemetry,
    required this.features,
    required this.sourceAttribution,
    required this.forecast,
    required this.advisory,
    required this.meshTopology,
    required this.compressionStats,
    required this.systemInfo,
    this.isLiveConnected = false,
    this.activeScenario = 'Clean Baseline',
    this.activeProfile = 'Campus',
    this.activeStandard = 'NAQI',
  });

  factory AeroSenseState.fromJson(Map<String, dynamic> json, {bool isLiveConnected = false, String scenario = 'Clean Baseline'}) {
    final rawTelemetry = json['telemetry'] as Map<String, dynamic>? ?? {};
    final rawFeatures = json['features'] as Map<String, dynamic>? ?? {};
    final rawSource = json['source_attribution'] as Map<String, dynamic>? ?? {};
    final rawForecast = json['forecast'] as Map<String, dynamic>? ?? {};
    final rawAdvisory = json['advisory'] as Map<String, dynamic>? ?? {};
    final rawMesh = json['mesh_topology'] as List<dynamic>? ?? [];
    final rawComp = json['compression_stats'] as Map<String, dynamic>? ?? {};
    final rawSys = json['system_info'] as Map<String, dynamic>? ?? {};

    return AeroSenseState(
      telemetry: TelemetryData.fromJson(rawTelemetry.isNotEmpty ? rawTelemetry : rawFeatures),
      features: FeaturesData.fromJson(rawFeatures),
      sourceAttribution: SourceAttribution.fromJson(rawSource),
      forecast: ForecastData.fromJson(rawForecast),
      advisory: AdvisoryData.fromJson(rawAdvisory),
      meshTopology: rawMesh.map((e) => MeshNodeInfo.fromJson(e as Map<String, dynamic>)).toList(),
      compressionStats: CompressionStats.fromJson(rawComp),
      systemInfo: SystemInfo.fromJson(rawSys),
      isLiveConnected: isLiveConnected,
      activeScenario: scenario,
      activeProfile: json['active_profile'] as String? ?? 'Campus',
      activeStandard: json['active_standard'] as String? ?? 'NAQI',
    );
  }
}
