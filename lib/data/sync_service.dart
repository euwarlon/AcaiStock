import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_queue.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  static const int _maxRetries = 5;
  static const int _initialDelayMs = 1000;
  static const double _backoffMultiplier = 2.0;
  static const int _maxDelayMs = 30000;

  SupabaseClient? _supabaseClient;
  Timer? _syncTimer;

  void initialize(SupabaseClient? client) {
    _supabaseClient = client;
    if (client != null) {
      _startPeriodicSync();
    }
  }

  void _startPeriodicSync() {
    // Sincroniza a cada 30 segundos quando há pendências
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (SyncQueue.instance.hasPendingSync && !SyncQueue.instance.isSyncing) {
        await syncWithServer();
      }
    });
  }

  Future<void> syncWithServer() async {
    if (_supabaseClient == null) {
      debugPrint(
          '[SyncService] Supabase não inicializado, ignorando sincronização.');
      return;
    }

    await SyncQueue.instance.syncWithServer((item) async {
      await _syncItemWithRetry(item, attempt: 1);
    });
  }

  Future<void> _syncItemWithRetry(SyncItem item, {required int attempt}) async {
    try {
      await _syncItem(item);
      debugPrint(
          '[SyncService] Sincronizado com sucesso: ${item.tableName} ${item.action.name}');
    } catch (e) {
      if (attempt < _maxRetries) {
        final delayMs = min(
          (_initialDelayMs * pow(_backoffMultiplier, attempt - 1)).toInt(),
          _maxDelayMs,
        );
        debugPrint(
          '[SyncService] Erro ao sincronizar (tentativa $attempt/$_maxRetries): $e. '
          'Tentando novamente em ${delayMs}ms',
        );
        await Future.delayed(Duration(milliseconds: delayMs));
        await _syncItemWithRetry(item, attempt: attempt + 1);
      } else {
        debugPrint(
            '[SyncService] Falha permanente após $_maxRetries tentativas: $e');
        rethrow;
      }
    }
  }

  Future<void> _syncItem(SyncItem item) async {
    if (_supabaseClient == null) throw StateError('Supabase não inicializado');

    switch (item.action) {
      case SyncAction.create:
        await _supabaseClient!.from(item.tableName).insert(item.data);
        break;
      case SyncAction.update:
        final id = item.data['id'];
        if (id == null) throw StateError('ID não encontrado para update');
        await _supabaseClient!
            .from(item.tableName)
            .update(item.data)
            .eq('id', id);
        break;
      case SyncAction.delete:
        final id = item.data['id'];
        if (id == null) throw StateError('ID não encontrado para delete');
        await _supabaseClient!.from(item.tableName).delete().eq('id', id);
        break;
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}
