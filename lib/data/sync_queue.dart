import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncAction { create, update, delete }

class SyncItem {
  SyncItem({
    required this.id,
    required this.action,
    required this.tableName,
    required this.data,
    required this.createdAt,
  });

  final String id;
  final SyncAction action;
  final String tableName;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action.name,
        'tableName': tableName,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      id: json['id'] as String,
      action: SyncAction.values.byName(json['action'] as String),
      tableName: json['tableName'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SyncQueue {
  SyncQueue._();
  static final SyncQueue instance = SyncQueue._();

  static const _storageKey = 'sync_queue_v1';
  final List<SyncItem> _queue = [];
  SharedPreferences? _prefs;
  bool _syncing = false;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _load();
  }

  Future<void> _load() async {
    if (_prefs == null) return;
    try {
      final raw = _prefs!.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        _queue.clear();
        return;
      }
      final list = jsonDecode(raw) as List<dynamic>;
      _queue.clear();
      _queue.addAll(
        list.map((e) => SyncItem.fromJson(Map<String, dynamic>.from(e as Map))),
      );
    } catch (_) {
      _queue.clear();
    }
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    try {
      await _prefs!.setString(
        _storageKey,
        jsonEncode(_queue.map((e) => e.toJson()).toList()),
      );
    } catch (_) {
      // Falha ao persistir
    }
  }

  Future<void> addSync({
    required SyncAction action,
    required String tableName,
    required Map<String, dynamic> data,
  }) async {
    final item = SyncItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: action,
      tableName: tableName,
      data: data,
      createdAt: DateTime.now(),
    );
    _queue.add(item);
    await _persist();
    debugPrint('[SyncQueue] Adicionado: ${item.tableName} ${item.action.name}');
  }

  Future<void> removeSync(String id) async {
    _queue.removeWhere((item) => item.id == id);
    await _persist();
    debugPrint('[SyncQueue] Removido: $id');
  }

  List<SyncItem> getPendingSync() => List.unmodifiable(_queue);

  bool get isSyncing => _syncing;
  bool get hasPendingSync => _queue.isNotEmpty;

  Future<void> syncWithServer(
    Future<void> Function(SyncItem item) onSync,
  ) async {
    if (_syncing || _queue.isEmpty) return;
    _syncing = true;

    final itemsToSync = [..._queue];
    for (final item in itemsToSync) {
      try {
        await onSync(item);
        await removeSync(item.id);
        debugPrint('[SyncQueue] Sincronizado: ${item.tableName} ${item.action.name}');
      } catch (e) {
        debugPrint('[SyncQueue] Erro ao sincronizar: $e');
        // Não remove do queue, tenta de novo na próxima sincronização
        break;
      }
    }

    _syncing = false;
  }

  Future<void> clear() async {
    _queue.clear();
    await _persist();
  }
}
