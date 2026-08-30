import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'local_db_service.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  factory SyncService() => instance;
  SyncService._internal();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        debugPrint('[SyncService] Internet connection restored. Triggering cloud sync...');
        syncPendingItems();
      }
    });

    // Initial sync check on launch
    syncPendingItems();
  }

  Future<void> syncPendingItems() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingQueue = await LocalDbService.instance.getPendingSyncItems();
      if (pendingQueue.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('[SyncService] Processing ${pendingQueue.length} pending local sync items...');

      for (final item in pendingQueue) {
        final int id = item['id'] as int;
        final String entityType = item['entity_type'] as String;
        final String action = item['action'] as String;
        final String payloadJson = item['payload_json'] as String;

        // Process item sync (simulated resilient sync or cloud sync)
        final success = await _uploadItem(entityType, action, payloadJson);
        if (success) {
          await LocalDbService.instance.removeSyncItem(id);
        }
      }

      debugPrint('[SyncService] Cloud sync completed.');
    } catch (e) {
      debugPrint('[SyncService] Error during cloud sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _uploadItem(String entityType, String action, String payloadJson) async {
    // Cloud sync endpoint integration
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
