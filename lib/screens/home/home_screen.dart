import 'package:acai_stock/models/product.dart';
import 'package:acai_stock/providers/app_store.dart';
import 'package:acai_stock/widgets/product_cards.dart';
import 'package:acai_stock/widgets/section_title.dart';
import 'package:acai_stock/widgets/status_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                onPressed: () {
                  final value = int.tryParse(controller.text.trim());
                  Navigator.of(ctx).pop(value);
                },
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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        return ListView(
          padding: EdgeInsets.all(compact ? 14 : 18),
          children: [
            Text(
              'Olá, ${store.currentUserName ?? 'Mariana'}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('Resumo do seu estoque', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: StatusCard(
                    title: 'Total de Produtos',
                    value: store.totalProducts.toString(),
                    subtitle: '+${store.weeklyGrowth} nos últimos 7 dias',
                    icon: Icons.inventory_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionTitle('Produtos com baixo estoque'),
            const SizedBox(height: 8),
            ...store.lowStockProducts.map((p) => ProductQuickRow(product: p)),
            const SizedBox(height: 16),
            const SectionTitle('Produtos em falta'),
            const SizedBox(height: 8),
            ...store.outProducts.map((p) => ActionRow(
                  title: p.nome,
                  subtitle: 'Sem estoque disponível',
                  button: 'Repor',
                  onPressed: () => _showRestockSheet(context, store, p),
                )),
          ],
        );
      },
    );
  }
}
