import 'dart:async';

import 'package:acai_stock/providers/app_store.dart';
import 'package:acai_stock/widgets/acai_button.dart';
import 'package:acai_stock/widgets/acai_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _emailController = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final store = context.read<AppStore>();
      final message = await store.recoverPassword(email: _emailController.text);
      if (!mounted) return;
      if (message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link de redefinição enviado. Verifique seu e-mail.'),
        ),
      );
      store.setAuthScreen(AuthScreen.login);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    return Column(
      key: const ValueKey('recovery'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Recuperar senha',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        const Text('Insira seu e-mail para receber um link de redefinição.'),
        const SizedBox(height: 20),
        AcaiField(
          controller: _emailController,
          label: 'Email',
          hint: 'seuemail@acai.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 22),
        AcaiButton(
          text: 'Enviar Link',
          loading: _busy,
          onPressed: () => unawaited(_submit()),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => store.setAuthScreen(AuthScreen.login),
          child: const Text('Voltar ao login'),
        ),
      ],
    );
  }
}
