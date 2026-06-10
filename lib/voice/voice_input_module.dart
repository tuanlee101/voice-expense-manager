import 'dart:async';
import '../models/voice_command.dart';
import 'speech_recognition_engine.dart';
import 'nlp_processor.dart';
import 'tts_engine.dart';

enum VoiceInputState { idle, listening, processing, speaking, error }

class VoiceInputModule {
  final SpeechRecognitionEngine _speechEngine;
  final NLPProcessor _nlpProcessor;
  final TTSEngine _ttsEngine;

  VoiceInputState _state = VoiceInputState.idle;
  String? _lastError;
  int _retryCount = 0;
  static const int maxRetries = 3;
  String _currentLanguage = 'vi-VN';
  bool _isPaused = false;
  bool _isVoiceDisabled = false;

  // Callbacks
  void Function(VoiceInputState state)? onStateChanged;
  void Function(VoiceCommand command)? onCommandProcessed;
  void Function(String text)? onPartialTranscript;
  void Function(String message)? onFeedback;
  void Function(VoiceCommand command)? onResult;

  VoiceInputModule({
    required SpeechRecognitionEngine speechEngine,
    required NLPProcessor nlpProcessor,
    required TTSEngine ttsEngine,
    this.onResult,
  })  : _speechEngine = speechEngine,
        _nlpProcessor = nlpProcessor,
        _ttsEngine = ttsEngine;

  VoiceInputState get state => _state;
  String? get lastError => _lastError;
  String get currentLanguage => _currentLanguage;
  bool get isVoiceDisabled => _isVoiceDisabled;

  set isVoiceDisabled(bool val) {
    _isVoiceDisabled = val;
  }

  set currentLanguage(String lang) {
    _currentLanguage = lang;
    _ttsEngine.setLanguage(lang);
  }

  void _setState(VoiceInputState newState) {
    _state = newState;
    onStateChanged?.call(newState);
  }

  /// Start voice input session
  Future<VoiceCommand?> startListening() async {
    if (_isPaused || _isVoiceDisabled) return null;

    _setState(VoiceInputState.listening);
    _retryCount = 0;

    return _listenWithRetry();
  }

  Future<VoiceCommand?> _listenWithRetry() async {
    while (_retryCount < maxRetries) {
      final locale = _currentLanguage == 'vi-VN' ? 'vi_VN' : 'en_US';

      final text = await _speechEngine.listen(
        locale: locale,
        silenceTimeout: const Duration(seconds: 2),
        maxDuration: const Duration(seconds: 10),
        minimumConfidence: 0.7,
      );

      if (text == null) {
        if (_speechEngine.lastError?.contains('No speech') ?? false) {
          final msg = _currentLanguage.startsWith('vi')
              ? 'Không nhận được giọng nói'
              : 'No speech detected';
          onFeedback?.call(msg);
          await _ttsEngine.speak(msg);
          _setState(VoiceInputState.idle);
          return null;
        }

        _retryCount++;
        if (_retryCount < maxRetries) {
          final msg = _currentLanguage.startsWith('vi')
              ? 'Xin hãy nói lại rõ hơn'
              : 'Please speak again';
          onFeedback?.call(msg);
          await _ttsEngine.speak(msg);
          _setState(VoiceInputState.listening);
          continue;
        } else {
          final msg = _currentLanguage.startsWith('vi')
              ? 'Đã thử 3 lần không thành công, vui lòng thử lại sau'
              : 'Failed after 3 attempts, please try again later';
          onFeedback?.call(msg);
          await _ttsEngine.speak(msg);
          _setState(VoiceInputState.error);
          return null;
        }
      }

      // Process with NLP
      _setState(VoiceInputState.processing);
      final command = _nlpProcessor.process(
        text,
        language: _currentLanguage.startsWith('vi') ? 'vi' : 'en',
      );

      if (command.confidence >= 0.6) {
        _retryCount = 0;
        onCommandProcessed?.call(command);
        _setState(VoiceInputState.idle);
        return command;
      } else {
        final msg = _currentLanguage.startsWith('vi')
            ? 'Không hiểu yêu cầu. Hãy nói rõ hơn.'
            : "I didn't understand. Please be more specific.";
        onFeedback?.call(msg);
        await _ttsEngine.speak(msg);
        _setState(VoiceInputState.idle);
        return command;
      }
    }

    _setState(VoiceInputState.idle);
    return null;
  }

  /// Start voice session and return result via callback
  Future<void> start({
    void Function(VoiceCommand command)? onResult,
  }) async {
    if (_isVoiceDisabled) return;
    final command = await startListening();
    if (command != null && onResult != null) {
      onResult(command);
    }
  }

  /// Stop listening (user initiated)
  Future<void> stopListening() async {
    await _speechEngine.stop();
    _retryCount = 0;
    _setState(VoiceInputState.idle);
  }

  /// Cancel current operation
  Future<void> cancel() async {
    await _speechEngine.cancel();
    if (_ttsEngine.isSpeaking) {
      await _ttsEngine.stop();
    }
    _retryCount = 0;
    _setState(VoiceInputState.idle);
  }

  /// Pause voice input
  void pause() {
    _isPaused = true;
  }

  /// Resume voice input
  void resume() {
    _isPaused = false;
  }

  /// Speak feedback text
  Future<void> speakFeedback(String message) async {
    _setState(VoiceInputState.speaking);
    _isPaused = true;
    await _ttsEngine.speakTimely(message);
    _isPaused = false;
    if (!_ttsEngine.isSpeaking) {
      _setState(VoiceInputState.idle);
    }
  }

  /// Handle stop word
  bool isStopCommand(String text) {
    final lower = text.toLowerCase().trim();
    final stopWords = ['dừng lại', 'thôi', 'stop', 'cancel', 'kết thúc'];
    return stopWords.any((w) => lower == w || lower.startsWith(w));
  }

  void dispose() {
    _speechEngine.dispose();
    _ttsEngine.dispose();
  }
}
