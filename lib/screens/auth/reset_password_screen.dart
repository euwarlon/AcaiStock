import 'dart:async';

import 'package:acai_stock/providers/app_store.dart';
import 'package:acai_stock/widgets/acai_button.dart';
import 'package:acai_stock/widgets/acai_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final store = context.read<AppStore>();
      final msg = await store.updateRecoveredPassword(
        password: _password.text,
        confirmPassword: _confirmPassword.text,
      );
      if (!mounted) return;
      if (msg != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Senha redefinida. Faça login novamente.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('reset-password'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Nova senha',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        const Text('Digite uma nova senha para concluir a recuperação.'),
        const SizedBox(height: 20),
        AcaiField(
          controller: _password,
          label: 'Nova senha',
          hint: '********',
          obscureText: true,
        ),
        const SizedBox(height: 14),
        AcaiField(
          controller: _confirmPassword,
          label: 'Confirmar senha',
          hint: '********',
          obscureText: true,
        ),
        const SizedBox(height: 22),
        AcaiButton(
          text: 'Salvar senha',
          loading: _busy,
          onPressed: () => unawaited(_submit()),
        ),
      ],
    );
  }
}
