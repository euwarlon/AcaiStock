import 'package:acai_stock/data/auth_service.dart';
import 'package:acai_stock/models/product.dart';
import 'package:acai_stock/providers/app_store.dart';
import 'package:acai_stock/widgets/product_cards.dart';
import 'package:acai_stock/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  AuthService get _authService => AuthService.instance;

  Future<void> _showRestockSheet(BuildContext context, AppStore store, Product product) async {
    final controller = TextEditingController();
    final qty = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Repor ${product.nome}', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade adicionada'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(int.tryParse(controller.text.trim())),
                child: const Text('Confirmar reposição'),
              ),
            ],
          ),
        );
      },
    );

    if (qty == null || qty <= 0 || !context.mounted) return;
    await store.restockProduct(product: product, addedQuantity: qty);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+${qty.toString()} adicionado em ${product.nome}')),
      );
    }
  }

  Future<void> _discard(BuildContext context, AppStore store, Product product) async {
    await store.discardLot(product);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lote ${product.lote} descartado e perda registrada.')),
      );
    }
  }

  Future<void> _export(BuildContext context, AppStore store) async {
    final ok = await _authService.authenticateOrSkip(
      reason: 'Confirme para exportar os dados',
    );
    if (!ok || !context.mounted) return;
    final paths = await store.exportReports();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Arquivos exportados:\n${paths.join('\n')}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Alertas',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Perdas (30 dias)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                '${store.lossQuantityLast30Days} itens descartados',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _export(context, store),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Exportar CSV/PDF'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionTitle('Críticos'),
        const SizedBox(height: 6),
        ...store.criticalAlerts.map(
          (p) => ActionRow(
            title: p.nome,
            subtitle: 'Estoque zerado no galpão',
            button: 'Repor',
            onPressed: () => _showRestockSheet(context, store, p),
            destructive: true,
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle('Vencimento'),
        const SizedBox(height: 6),
        ...store.expiryAlerts.map((p) {
          final days = p.dataValidade.difference(DateTime.now()).inDays;
          return ExpiryRow(
            title: p.nome,
            lot: p.lote,
            days: days,
            onDiscard: () => _discard(context, store, p),
            onReview: () {},
          );
        }),
      ],
    );
  }
}
