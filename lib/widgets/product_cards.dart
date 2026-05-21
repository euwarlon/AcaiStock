import 'package:acai_stock/models/product.dart';
import 'package:acai_stock/theme/app_theme.dart';
import 'package:acai_stock/widgets/acai_tile.dart';
import 'package:flutter/material.dart';

class ProductQuickRow extends StatelessWidget {
  const ProductQuickRow({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return AcaiTile(
      title: product.nome,
      subtitle: 'Quantidade: ${product.quantidade}',
      trailing: Text(
        product.quantidade.toString(),
        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.orange),
      ),
    );
  }
}

class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onPressed,
    this.destructive = false,
  });

  final String title;
  final String subtitle;
  final String button;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return AcaiTile(
      title: title,
      subtitle: subtitle,
      trailing: TextButton(
        onPressed: onPressed,
        child: Text(
          button,
          style: TextStyle(color: destructive ? Colors.redAccent : AppTheme.primary, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class ExpiryRow extends StatelessWidget {
  const ExpiryRow({
    super.key,
    required this.title,
    required this.lot,
    required this.days,
    required this.onDiscard,
    this.onReview,
  });

  final String title;
  final String lot;
  final int days;
  final VoidCallback onDiscard;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    return AcaiTile(
      title: title,
      subtitle: 'Lote $lot • vence em $days dia(s)',
      trailing: Wrap(
        spacing: 6,
        children: [
          TextButton(onPressed: onDiscard, child: const Text('Descartar')),
          TextButton(onPressed: onReview, child: const Text('Revisar')),
        ],
      ),
    );
  }
}

class ProductDetailCard extends StatelessWidget {
  const ProductDetailCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
  });

  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final status = product.outOfStock
        ? 'Out of Stock'
        : product.lowStock
            ? 'Low'
            : 'In Stock';
    final statusColor = product.outOfStock
        ? Colors.red
        : product.lowStock
            ? Colors.orange
            : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(product.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha((0.16 * 255).round()),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Categoria: ${product.categoria}'),
          Text('Quantidade atual: ${product.quantidade}'),
          Text('Tendência semanal: ${product.trend >= 0 ? '+' : ''}${product.trend}'),
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onEdit != null)
                  TextButton(onPressed: onEdit, child: const Text('Editar')),
                if (onDelete != null)
                  TextButton(
                    onPressed: onDelete,
                    child: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
