// services/voice_assistant_service.dart
// On-device text-to-speech environmental briefings and tactile haptic alerts.

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceAssistantService {
  static final VoiceAssistantService _instance = VoiceAssistantService._internal();
  factory VoiceAssistantService() => _instance;
  VoiceAssistantService._internal();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeaking = false;
  bool _initialized = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> _initIfNeeded() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.52);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
      });
      _initialized = true;
    } catch (_) {}
  }

  /// Speaks the given advisory or status briefing aloud
  Future<void> speakAdvisory(String text) async {
    await _initIfNeeded();
    try {
      if (_isSpeaking) {
        await stopSpeaking();
        return;
      }
      _isSpeaking = true;
      await _tts.speak(text);
    } catch (_) {
      _isSpeaking = false;
    }
  }

  /// Stops any currently active voice playback
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (_) {}
  }

  /// Triggers haptic tactile alerts based on environmental hazard severity
  Future<void> triggerHapticAlert(String severity) async {
    if (kIsWeb) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) return;

      if (severity == 'critical' || severity == 'hazardous') {
        // Double urgent pulse for high hazards
        if (await Vibration.hasCustomVibrationsSupport()) {
          await Vibration.vibrate(pattern: [0, 250, 100, 400], intensities: [0, 255, 0, 255]);
        } else {
          await Vibration.vibrate(duration: 500);
        }
      } else if (severity == 'warning') {
        await Vibration.vibrate(duration: 200);
      } else {
        await Vibration.vibrate(duration: 50);
      }
    } catch (_) {}
  }

  /// Plays a subtle audio chime for alert confirmation
  Future<void> playAlertChime() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/alert_chime.mp3'));
    } catch (_) {
      // Graceful fallback if asset file is optional
    }
  }

  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
  }
}
