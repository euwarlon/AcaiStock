import 'package:acai_stock/models/product.dart';
import 'package:acai_stock/providers/app_store.dart';
import 'package:acai_stock/screens/products/product_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum ProductSortOption {
  name,
  quantityAsc,
  quantityDesc,
  expirySoonest,
  reorderPoint
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String categoryFilter = 'All Stock';
  String stockFilter = 'All';
  String query = '';
  ProductSortOption sortOption = ProductSortOption.name;
  int currentPage = 1;
  static const int pageSize = 15;
  int totalProducts = 0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (currentPage * pageSize < totalProducts) {
        setState(() => currentPage++);
      }
    }
  }

  List<Product> _sortedProducts(List<Product> products) {
    final sorted = [...products];
    switch (sortOption) {
      case ProductSortOption.name:
        sorted.sort((a, b) => a.nome.compareTo(b.nome));
        break;
      case ProductSortOption.quantityAsc:
        sorted.sort((a, b) => a.quantidade.compareTo(b.quantidade));
        break;
      case ProductSortOption.quantityDesc:
        sorted.sort((a, b) => b.quantidade.compareTo(a.quantidade));
        break;
      case ProductSortOption.expirySoonest:
        sorted.sort((a, b) => a.dataValidade.compareTo(b.dataValidade));
        break;
      case ProductSortOption.reorderPoint:
        sorted.sort((a, b) => a.pontoPedido.compareTo(b.pontoPedido));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final categories = store.productCategories;
    final filtered = store.filterProducts(
      search: query,
      category: categoryFilter,
      stockStatus: stockFilter,
    );
    totalProducts = filtered.length;

    if (!categories.contains(categoryFilter)) {
      categoryFilter = categories.first;
    }

    final sorted = _sortedProducts(filtered);
    final paginated =
        sorted.skip((currentPage - 1) * pageSize).take(pageSize).toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount:
          paginated.length + (currentPage * pageSize < totalProducts ? 2 : 1),
      itemBuilder: (context, index) {
        // Header filters
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Products',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por nome ou lote'),
                onChanged: (value) {
                  setState(() {
                    query = value;
                    currentPage = 1;
                  });
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories
                    .map(
                      (chip) => ChoiceChip(
                        label: Text(chip),
                        selected: categoryFilter == chip,
                        onSelected: (_) {
                          setState(() {
                            categoryFilter = chip;
                            currentPage = 1;
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'All', label: Text('Todos')),
                  ButtonSegment(value: 'In Stock', label: Text('In Stock')),
                  ButtonSegment(value: 'Low', label: Text('Low')),
                  ButtonSegment(value: 'Out of Stock', label: Text('Out')),
                ],
                selected: {stockFilter},
                onSelectionChanged: (selection) {
                  setState(() {
                    stockFilter = selection.first;
                    currentPage = 1;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ProductSortOption>(
                      initialValue: sortOption,
                      decoration:
                          const InputDecoration(labelText: 'Ordenar por'),
                      items: const [
                        DropdownMenuItem(
                            value: ProductSortOption.name, child: Text('Nome')),
                        DropdownMenuItem(
                            value: ProductSortOption.quantityAsc,
                            child: Text('Quantidade ↑')),
                        DropdownMenuItem(
                            value: ProductSortOption.quantityDesc,
                            child: Text('Quantidade ↓')),
                        DropdownMenuItem(
                            value: ProductSortOption.expirySoonest,
                            child: Text('Validade')),
                        DropdownMenuItem(
                            value: ProductSortOption.reorderPoint,
                            child: Text('Ponto de pedido')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            sortOption = value;
                            currentPage = 1;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Novo'),
                    onPressed: () async {
                      final created = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                            builder: (_) => const ProductEditorScreen()),
                      );
                      if (created == true && mounted) {
                        setState(() => currentPage = 1);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('$totalProducts produtos encontrados',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
            ],
          );
        }

        final productIndex = index - 1;
        if (productIndex >= paginated.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(),
          );
        }

        final product = paginated[productIndex];
        return _buildProductItem(context, store, product);
      },
    );
  }

  Widget _buildProductItem(
      BuildContext context, AppStore store, Product product) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () async {
          final updated = await Navigator.of(context).push<Product>(
            MaterialPageRoute(
                builder: (_) => ProductEditorScreen(product: product)),
          );
          if (updated != null && mounted) {
            setState(() {});
          }
        },
        title: Text(product.nome),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${product.categoria} • Lote: ${product.lote}'),
            Text('Qtd: ${product.quantidade} (Ponto: ${product.pontoPedido})',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (ctx) => [
            PopupMenuItem(
              onTap: () async {
                final updated = await Navigator.of(context).push<Product>(
                  MaterialPageRoute(
                      builder: (_) => ProductEditorScreen(product: product)),
                );
                if (updated != null && mounted) {
                  setState(() {});
                }
              },
              child: const Text('Editar'),
            ),
            PopupMenuItem(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Deletar'),
                    content:
                        Text('Tem certeza que quer deletar ${product.nome}?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar')),
                      FilledButton(
                        onPressed: () async {
                          await store.deleteProduct(product);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Deletar'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Deletar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
