import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalUserAccount {
  LocalUserAccount({
    required this.email,
    required this.name,
    required this.passwordHash,
  });

  final String email;
  final String name;
  final String passwordHash;

  Map<String, dynamic> toJson() => {
        'email': email,
        'name': name,
        'ph': passwordHash,
      };

  factory LocalUserAccount.fromJson(Map<String, dynamic> j) {
    return LocalUserAccount(
      email: j['email'] as String,
      name: j['name'] as String,
      passwordHash: j['ph'] as String,
    );
  }
}

class LocalCredentialsStore {
  LocalCredentialsStore();

  static const _secureStorageKey = 'local_user_accounts_v2';
  static const _secureStorage = FlutterSecureStorage();

  List<LocalUserAccount> _accounts = [];

  String _normEmail(String email) => email.trim().toLowerCase();

  static String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  static bool verifyPassword(String password, String hash) {
    try {
      return BCrypt.checkpw(password, hash);
    } catch (_) {
      return false;
    }
  }

  Future<void> reload() async {
    try {
      final raw = await _secureStorage.read(key: _secureStorageKey);
      if (raw == null || raw.isEmpty) {
        _accounts = [];
        return;
      }
      final list = jsonDecode(raw) as List<dynamic>;
      _accounts =
          list.map((e) => LocalUserAccount.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      _accounts = [];
    }
  }

  Future<void> _persist() async {
    try {
      await _secureStorage.write(
        key: _secureStorageKey,
        value: jsonEncode(_accounts.map((a) => a.toJson()).toList()),
      );
    } catch (_) {
      // Falha ao persistir
    }
  }

  Future<void> clear() async {
    _accounts = [];
    try {
      await _secureStorage.delete(key: _secureStorageKey);
    } catch (_) {
      // Falha ao limpar
    }
  }

  String? validateEmailFormat(String email) {
    final t = email.trim();
    if (t.isEmpty) return 'Informe um e-mail.';
    if (!t.contains('@') || !t.contains('.')) return 'E-mail inválido.';
    return null;
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final n = name.trim();
    if (n.isEmpty) return 'Informe seu nome.';
    final emailErr = validateEmailFormat(email);
    if (emailErr != null) return emailErr;
    final e = _normEmail(email);
    if (password.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
    if (_accounts.any((a) => a.email == e)) return 'Este e-mail já está cadastrado.';
    _accounts.add(
      LocalUserAccount(
        email: e,
        name: n,
        passwordHash: hashPassword(password),
      ),
    );
    await _persist();
    return null;
  }

  LocalUserAccount? _findByNormalizedEmail(String normalizedEmail) {
    for (final a in _accounts) {
      if (a.email == normalizedEmail) return a;
    }
    return null;
  }

  String? validateLogin(String email, String password) {
    if (email.trim().isEmpty || password.isEmpty) {
      return 'Preencha e-mail e senha.';
    }
    final emailErr = validateEmailFormat(email);
    if (emailErr != null) return emailErr;
    final e = _normEmail(email);
    final account = _findByNormalizedEmail(e);
    if (account == null) return 'E-mail não cadastrado.';
    if (!verifyPassword(password, account.passwordHash)) return 'Senha incorreta.';
    return null;
  }

  LocalUserAccount? accountForEmail(String rawEmail) {
    return _findByNormalizedEmail(_normEmail(rawEmail));
  }
}
