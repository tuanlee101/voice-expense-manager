import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/database_service.dart';

class SyncService {
  final DatabaseService _db;
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;
  Timer? _retryTimer;
  int _retryDelay = 1; // seconds, exponential backoff

  SyncService(this._db);

  /// Start listening for connectivity changes
  Future<void> initialize() async {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        _syncIfNeeded();
      }
    });
  }

  /// Sync data with cloud (R9.3 - R9.4)
  Future<void> syncData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final queue = await _db.getSyncQueue();
      if (queue.isEmpty) return;

      int successCount = 0;
      for (final _ in queue) {
        try {
          // Simulate cloud sync - in production, send to actual API
          // await _apiClient.sync(item);
          successCount++;
        } catch (e) {
          _retryDelay = (_retryDelay * 2).clamp(1, 16);
          if (_retryDelay >= 16) {
            // Max retries reached
            _retryDelay = 1;
            break;
          }
          await Future.delayed(Duration(seconds: _retryDelay));
        }
      }

      if (successCount == queue.length) {
        await _db.clearSyncQueue();
        _retryDelay = 1;
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncIfNeeded() async {
    final queue = await _db.getSyncQueue();
    if (queue.isNotEmpty) {
      await syncData();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
  }
}
