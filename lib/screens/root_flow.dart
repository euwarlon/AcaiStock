import 'package:acai_stock/providers/app_store.dart';
import 'package:acai_stock/screens/auth/auth_gate.dart';
import 'package:acai_stock/screens/main/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RootFlow extends StatelessWidget {
  const RootFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    if (store.isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (store.isPasswordRecoveryMode || !store.isLoggedIn) {
      return const AuthGate();
    }
    return const MainScaffold();
  }
}
