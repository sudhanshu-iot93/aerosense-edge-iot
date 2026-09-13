import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import '../models/air_quality_state.dart';
import '../theme/app_theme.dart';

class ARVisionScreen extends StatefulWidget {
  final AeroSenseState state;

  const ARVisionScreen({super.key, required this.state});

  @override
  State<ARVisionScreen> createState() => _ARVisionScreenState();
}

class _ARVisionScreenState extends State<ARVisionScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  double _xOffset = 0.0;
  double _yOffset = 0.0;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initSensors();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  void _initSensors() {
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          // Simple mapping of gyro to offset
          _xOffset += event.y * 15;
          _yOffset += event.x * 15;

          // Clamp offsets
          _xOffset = _xOffset.clamp(-150.0, 150.0);
          _yOffset = _yOffset.clamp(-200.0, 200.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _gyroSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Theme.of(context).extension<AeroTheme>()!.primaryEmerald),
        ),
      );
    }

    final aqi = widget.state.features.aqi;
    final source = widget.state.sourceAttribution.primarySource;
    final color = AeroTheme.getAqiColor(aqi);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'AR Pollution Vision',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Viewfinder
          CameraPreview(_controller!),
          
          // 2. AR Overlay (Floating Tags)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            left: (MediaQuery.of(context).size.width / 2) - 100 + _xOffset,
            top: (MediaQuery.of(context).size.height / 2) - 80 + _yOffset,
            child: _buildARCard(aqi, source, color),
          ),
          
          // 3. Static Crosshair
          const Center(
            child: Icon(Icons.add, color: Colors.white54, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildARCard(int aqi, String source, Color aqiColor) {
    return Container(
      width: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AeroTheme>()!.bgDark.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: aqiColor.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: aqiColor.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$aqi',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: aqiColor,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 10)
              ]
            ),
          ),
          Text(
            'AQI',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              source,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }
}
