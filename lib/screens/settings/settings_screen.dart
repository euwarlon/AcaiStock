import 'dart:async';

import 'package:acai_stock/providers/app_store.dart';
import 'package:acai_stock/widgets/acai_button.dart';
import 'package:acai_stock/widgets/acai_tile.dart';
import 'package:acai_stock/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Configurações',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        const SectionTitle('Perfil'),
        const SizedBox(height: 8),
        AcaiTile(
          title: store.currentUserName ?? 'Usuário',
          subtitle: 'Gerente',
        ),
        const SizedBox(height: 14),
        const SectionTitle('Preferências'),
        const SizedBox(height: 8),
        SwitchListTile(
          secondary: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.primary),
          value: store.notifications,
          onChanged: (value) {
            unawaited(store.toggleNotifications(value));
          },
          title: const Text('Notificações'),
        ),
        SwitchListTile(
          secondary: Icon(Icons.dark_mode_outlined, color: Theme.of(context).colorScheme.primary),
          value: store.darkMode,
          onChanged: (value) => unawaited(store.toggleDarkMode(value)),
          title: const Text('Modo Escuro'),
        ),
        DropdownButtonFormField<String>(
          initialValue: store.language,
          decoration: const InputDecoration(labelText: 'Idioma'),
          items: const [
            DropdownMenuItem(value: 'Português', child: Text('Português')),
            DropdownMenuItem(value: 'English', child: Text('English')),
            DropdownMenuItem(value: 'Español', child: Text('Español')),
          ],
          onChanged: (value) {
            if (value != null) store.setLanguage(value);
          },
        ),
        const SizedBox(height: 20),
        AcaiButton(
          text: 'Backup em Nuvem',
          onPressed: () async {
            try {
              final remotePath =
                  await context.read<AppStore>().backupDatabaseToCloud();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Backup enviado: $remotePath')),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Falha no backup: $e')),
              );
            }
          },
        ),
        const SizedBox(height: 10),
        AcaiButton(
          text: 'Sair da Conta',
          onPressed: () async => await context.read<AppStore>().logout(),
          outlined: true,
        ),
      ],
    );
  }
}
