import 'dart:async';

import 'package:acai_stock/providers/app_store.dart';
import 'package:acai_stock/widgets/acai_button.dart';
import 'package:acai_stock/widgets/acai_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final store = context.read<AppStore>();
      final msg = await store.registerAccount(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        if (msg.contains('Verifique o e-mail')) {
          store.setAuthScreen(AuthScreen.login);
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada e login realizado com sucesso.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Criar conta', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        AcaiField(controller: _name, label: 'Nome', hint: 'Mariana'),
        const SizedBox(height: 14),
        AcaiField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          label: 'Email',
          hint: 'seuemail@acai.com',
        ),
        const SizedBox(height: 14),
        AcaiField(controller: _password, label: 'Senha', hint: '********', obscureText: true),
        const SizedBox(height: 24),
        AcaiButton(text: 'Cadastrar', loading: _busy, onPressed: () => unawaited(_submit())),
        TextButton(
          onPressed: () => store.setAuthScreen(AuthScreen.login),
          child: const Text('Já tenho conta'),
        ),
      ],
    );
  }
}
