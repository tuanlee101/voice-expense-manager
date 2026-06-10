import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechRecognitionEngine {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String? _lastError;
  StreamSubscription? _statusSubscription;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String? get lastError => _lastError;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (error) {
          _lastError = error.errorMsg;
        },
        onStatus: (status) {
          // Status updates handled internally
        },
      );
      return _isAvailable;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<String?> listen({
    required String locale,
    Duration silenceTimeout = const Duration(seconds: 2),
    Duration maxDuration = const Duration(seconds: 10),
    double minimumConfidence = 0.7,
  }) async {
    if (!_isAvailable) {
      _lastError = 'Speech recognition not available';
      return null;
    }

    if (_isListening) {
      await stop();
    }

    _isListening = true;
    _lastError = null;

    final completer = Completer<String?>();
    String? resultText;
    double? resultConfidence;

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult) {
            resultText = result.recognizedWords;
            resultConfidence = result.confidence;
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: locale,
          listenFor: maxDuration,
          pauseFor: silenceTimeout,
          partialResults: false,
        ),
      );

      // Wait for final result
      await Future.delayed(const Duration(milliseconds: 100));
      final attempts = maxDuration.inMilliseconds ~/ 100;
      for (int i = 0; i < attempts; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (resultText != null) {
          final conf = resultConfidence;
          if (conf != null && conf < minimumConfidence) {
            _lastError =
                'Low confidence: ${(conf * 100).toStringAsFixed(0)}%';
            completer.complete(null);
            return completer.future;
          }
          completer.complete(resultText);
          return completer.future;
        }
      }

      // Timeout - no speech detected
      _lastError = 'No speech detected';
      completer.complete(null);
    } catch (e) {
      _lastError = e.toString();
      completer.complete(null);
    } finally {
      _isListening = false;
    }

    return completer.future;
  }

  Future<void> stop() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  Future<void> cancel() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
    }
  }

  void dispose() {
    _statusSubscription?.cancel();
    _speech.stop();
  }
}
