import 'package:acai_stock/providers/app_store.dart';
import 'package:acai_stock/screens/auth/login_screen.dart';
import 'package:acai_stock/screens/auth/recovery_screen.dart';
import 'package:acai_stock/screens/auth/register_screen.dart';
import 'package:acai_stock/screens/auth/reset_password_screen.dart';
import 'package:acai_stock/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                16 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.inventory_2_rounded,
                      size: 52,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Açaí Stock',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: switch (store.authScreen) {
                        AuthScreen.login => const LoginScreen(),
                        AuthScreen.register => const RegisterScreen(),
                        AuthScreen.recovery => const RecoveryScreen(),
                        AuthScreen.resetPassword => const ResetPasswordScreen(),
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
