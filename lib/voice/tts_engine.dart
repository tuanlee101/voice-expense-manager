import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSEngine {
  final FlutterTts _tts = FlutterTts();
  double _speechRate = 0.5; // 0.5x to 2.0x mapped to FlutterTTS range
  bool _isSpeaking = false;
  String? _currentLanguage;
  VoidCallback? onSpeechStart;
  VoidCallback? onSpeechEnd;

  bool get isSpeaking => _isSpeaking;

  double get speechRate => _speechRate;

  /// rate: 0.5 to 2.0
  set speechRate(double rate) {
    _speechRate = rate.clamp(0.5, 2.0);
    _tts.setSpeechRate(_speechRate);
  }

  Future<bool> initialize({String language = 'vi-VN'}) async {
    try {
      _currentLanguage = _mapLanguage(language);
      await _tts.setLanguage(_currentLanguage!);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
        onSpeechStart?.call();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        onSpeechEnd?.call();
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        onSpeechEnd?.call();
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        print('TTS Error: $msg');
        onSpeechEnd?.call();
      });

      return true;
    } catch (e) {
      print('TTS init error: $e');
      return false;
    }
  }

  String _mapLanguage(String language) {
    switch (language) {
      case 'vi-VN':
      case 'vi':
        return 'vi-VN';
      case 'en-US':
      case 'en':
      default:
        return 'en-US';
    }
  }

  Future<bool> speak(String text) async {
    if (text.isEmpty) return false;
    try {
      await _tts.speak(text);
      return true;
    } catch (e) {
      print('TTS speak error: $e');
      return false;
    }
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
    }
  }

  /// Speak within 2 seconds (requirement R8.1)
  Future<void> speakTimely(String text) async {
    await Future.delayed(const Duration(milliseconds: 100));
    await speak(text);
  }

  /// Say waiting message if processing > 2 seconds
  Future<void> speakWaitingIfNeeded(DateTime startTime) async {
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed.inMilliseconds > 2000) {
      await speak('Đang xử lý, vui lòng chờ...');
    }
  }

  void setLanguage(String language) {
    _currentLanguage = _mapLanguage(language);
    _tts.setLanguage(_currentLanguage!);
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
