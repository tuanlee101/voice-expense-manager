import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const _pinKey = 'voice_expense_pin';
  static const _encryptionKey = 'voice_expense_enc_key';

  bool _isAuthenticated = false;
  int _failedAttempts = 0;
  DateTime? _lastActivity;
  static const int maxFailedAttempts = 3;
  static const int inactivityTimeout = 5; // minutes

  bool get isAuthenticated => _isAuthenticated;
  int get failedAttempts => _failedAttempts;

  /// Check if PIN is set (first time setup)
  Future<bool> hasPin() async {
    final pin = await _secureStorage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  /// Set master PIN (first time)
  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _secureStorage.write(key: _pinKey, value: hash);
  }

  /// Verify PIN
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _secureStorage.read(key: _pinKey);
    if (storedHash == null) return false;

    final isValid = storedHash == _hashPin(pin);
    if (isValid) {
      _isAuthenticated = true;
      _failedAttempts = 0;
      _lastActivity = DateTime.now();
    } else {
      _failedAttempts++;
    }
    return isValid;
  }

  /// Get encryption key for data encryption (R10.3)
  Future<encrypt.Key> getEncryptionKey() async {
    String? keyStr = await _secureStorage.read(key: _encryptionKey);
    if (keyStr == null) {
      // Generate new AES-256 key
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      keyStr = base64Encode(keyBytes);
      await _secureStorage.write(key: _encryptionKey, value: keyStr);
    }
    return encrypt.Key.fromBase64(keyStr);
  }

  /// Encrypt data (R10.3)
  Future<String> encryptData(String plainText) async {
    final key = await getEncryptionKey();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  /// Decrypt data (R10.3)
  Future<String> decryptData(String encryptedText) async {
    final parts = encryptedText.split(':');
    if (parts.length != 2) throw ArgumentError('Invalid encrypted text');

    final key = await getEncryptionKey();
    final iv = encrypt.IV(base64Decode(parts[0]));
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt64(parts[1], iv: iv);
  }

  /// Check inactivity timeout (R10.5)
  bool isSessionExpired() {
    if (_lastActivity == null) return true;
    final elapsed = DateTime.now().difference(_lastActivity!);
    return elapsed.inMinutes >= inactivityTimeout;
  }

  /// Lock the session
  void lock() {
    _isAuthenticated = false;
  }

  /// Reset failed attempts after successful re-auth
  void resetFailedAttempts() {
    _failedAttempts = 0;
  }

  /// Check if voice should be disabled (R10.6)
  bool isVoiceDisabled() => _failedAttempts >= maxFailedAttempts;

  /// Reset everything (account deletion - R10.4)
  Future<void> deleteAllData() async {
    await _secureStorage.deleteAll();
    _isAuthenticated = false;
    _failedAttempts = 0;
    _lastActivity = null;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final salt = utf8.encode('voice_expense_salt_2024');
    final combined = [...bytes, ...salt];
    return sha256.convert(combined).toString();
  }
}
