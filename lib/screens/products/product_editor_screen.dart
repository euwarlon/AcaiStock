import 'package:acai_stock/models/product.dart';
import 'package:acai_stock/providers/app_store.dart';
import 'package:acai_stock/providers/qr_scanner_provider.dart';
import 'package:acai_stock/screens/qr_scanner_screen.dart';
import 'package:acai_stock/widgets/acai_button.dart';
import 'package:acai_stock/widgets/acai_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductEditorScreen extends StatefulWidget {
  const ProductEditorScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _quantityController;
  late final TextEditingController _reorderPointController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _lotController;
  late final TextEditingController _trendController;
  DateTime? _expiryDate;
  bool _galpaoZerado = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.nome ?? '');
    _categoryController = TextEditingController(text: product?.categoria ?? '');
    _quantityController = TextEditingController(text: product?.quantidade.toString() ?? '0');
    _reorderPointController = TextEditingController(text: product?.pontoPedido.toString() ?? '0');
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
    _lotController = TextEditingController(text: product?.lote ?? '');
    _trendController = TextEditingController(text: product?.trend.toString() ?? '0');
    _expiryDate = product?.dataValidade ?? DateTime.now().add(const Duration(days: 30));
    _galpaoZerado = product?.galpaoZerado ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _reorderPointController.dispose();
    _barcodeController.dispose();
    _lotController.dispose();
    _trendController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (selected != null) {
      setState(() => _expiryDate = selected);
    }
  }

  Future<void> _scanQrCode() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => QrScannerProvider(),
          child: const QrScannerScreen(),
        ),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _barcodeController.text = result;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código lido: $result'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final lot = _lotController.text.trim();
    final barcode = _barcodeController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim()) ?? -1;
    final reorderPoint = int.tryParse(_reorderPointController.text.trim()) ?? -1;
    final trend = int.tryParse(_trendController.text.trim()) ?? 0;
    final expiryDate = _expiryDate;

    if (name.isEmpty || category.isEmpty || lot.isEmpty || expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, categoria, lote e validade.')),
      );
      return;
    }

    if (quantity < 0 || reorderPoint < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantidade e ponto de pedido devem ser valores válidos.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final store = context.read<AppStore>();
      final product = widget.product?.copyWith(
            nome: name,
            categoria: category,
            quantidade: quantity,
            pontoPedido: reorderPoint,
            barcode: barcode.isEmpty ? null : barcode,
            lote: lot,
            dataValidade: expiryDate,
            trend: trend,
            galpaoZerado: _galpaoZerado,
          ) ??
          Product(
            nome: name,
            categoria: category,
            quantidade: quantity,
            pontoPedido: reorderPoint,
            barcode: barcode.isEmpty ? null : barcode,
            lote: lot,
            dataValidade: expiryDate,
            trend: trend,
            galpaoZerado: _galpaoZerado,
          );

      final error = await store.saveProduct(product);
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        return;
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Produto' : 'Novo Produto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AcaiField(label: 'Nome', hint: 'Açaí Base', controller: _nameController),
          const SizedBox(height: 12),
          AcaiField(label: 'Categoria', hint: 'Embalagens', controller: _categoryController),
          const SizedBox(height: 12),
          AcaiField(label: 'Lote', hint: 'AC-203', controller: _lotController),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AcaiField(
                  label: 'Barcode',
                  hint: '789101',
                  controller: _barcodeController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: IconButton.filled(
                  onPressed: _scanQrCode,
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Ler código QR',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AcaiField(
                  label: 'Quantidade',
                  hint: '10',
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AcaiField(
                  label: 'Ponto de pedido',
                  hint: '5',
                  controller: _reorderPointController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AcaiField(
                  label: 'Tendência',
                  hint: '0',
                  controller: _trendController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Validade'),
                    const SizedBox(height: 6),
                    FilledButton(
                      onPressed: _pickExpiryDate,
                      child: Text(_expiryDate == null
                          ? 'Selecionar data'
                          : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Galpão zerado'),
            value: _galpaoZerado,
            onChanged: (value) => setState(() => _galpaoZerado = value),
          ),
          const SizedBox(height: 24),
          AcaiButton(text: isEditing ? 'Salvar Alterações' : 'Adicionar Produto', loading: _busy, onPressed: _save),
        ],
      ),
    );
  }
}
