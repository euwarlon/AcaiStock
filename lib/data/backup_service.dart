import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BackupService {
  Future<String> backupSQLiteToSupabase(SupabaseClient? client) async {
    const bucket = String.fromEnvironment('SUPABASE_BACKUP_BUCKET',
        defaultValue: 'backups');

    if (client == null) {
      throw Exception('Supabase nao esta configurado para backup em nuvem.');
    }

    final dbDir = await getDatabasesPath();
    final dbFile = File(p.join(dbDir, 'acai_stock.db'));
    if (!await dbFile.exists()) {
      throw Exception('Banco local não encontrado para backup.');
    }

    final remotePath = 'acai_stock_${DateTime.now().millisecondsSinceEpoch}.db';
    await client.storage.from(bucket).upload(
          remotePath,
          dbFile,
          fileOptions: const FileOptions(upsert: true),
        );
    return '$bucket/$remotePath';
  }
}
