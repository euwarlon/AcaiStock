import 'dart:async';

import 'package:acai_stock/providers/app_store.dart';
import 'package:acai_stock/widgets/acai_button.dart';
import 'package:acai_stock/widgets/acai_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final store = context.read<AppStore>();
      final msg = await store.loginWithCredentials(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login realizado com sucesso.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Faça o seu login', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        AcaiField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          label: 'Email',
          hint: 'seuemail@acai.com',
        ),
        const SizedBox(height: 14),
        AcaiField(controller: _password, label: 'Senha', hint: '********', obscureText: true),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => store.setAuthScreen(AuthScreen.recovery),
            child: const Text('Esqueceu sua senha?'),
          ),
        ),
        const SizedBox(height: 10),
        AcaiButton(text: 'Login', loading: _busy, onPressed: () => unawaited(_submit())),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => store.setAuthScreen(AuthScreen.register),
          child: const Text('Criar conta'),
        ),
      ],
    );
  }
}
