import 'dart:async';

import 'package:flutter/material.dart';
import 'sync_queue.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  Timer? _syncTimer;

  void initialize() {
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (SyncQueue.instance.hasPendingSync && !SyncQueue.instance.isSyncing) {
        await syncWithServer();
      }
    });
  }

  Future<void> syncWithServer() async {
    debugPrint('[SyncService] Sincronização remota não configurada. Ignorando.');
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}
