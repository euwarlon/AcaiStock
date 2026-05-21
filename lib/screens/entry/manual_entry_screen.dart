import 'package:acai_stock/theme/app_theme.dart';
import 'package:acai_stock/providers/app_store.dart';
import 'package:acai_stock/widgets/acai_button.dart';
import 'package:acai_stock/widgets/acai_field.dart';
import 'package:acai_stock/widgets/acai_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _code = TextEditingController();
  final _qty = TextEditingController(text: '1');
  String _barcode = '';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final hasCode = _barcode.trim().isNotEmpty;
    final match = hasCode ? store.productByBarcode(_barcode.trim()) : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Digitar Código')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AcaiField(
            label: 'SKU / Barcode',
            hint: '789101',
            controller: _code,
            keyboardType: TextInputType.number,
            onChanged: (value) => setState(() => _barcode = value),
          ),
          const SizedBox(height: 12),
          AcaiField(
            label: 'Quantidade',
            hint: '1',
            controller: _qty,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const Text('Possível Correspondência', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AcaiTile(
            title: !hasCode
                ? 'Aguardando código'
                : match != null
                    ? match.nome
                    : 'Nenhuma correspondência',
            subtitle: !hasCode
                ? 'Digite um SKU/Barcode para buscar'
                : match != null
                    ? '${match.categoria} • estoque: ${match.quantidade}'
                    : 'Cadastre este produto antes de dar entrada',
            trailing: Icon(
              match != null ? Icons.check_circle : Icons.info_outline,
              color: match != null ? AppTheme.primary : Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          AcaiButton(
            text: 'Confirmar',
            loading: _busy,
            onPressed: (!hasCode || match == null || _busy)
                ? () {}
                : () async {
                    setState(() => _busy = true);
                    try {
                      final qty = int.tryParse(_qty.text.trim()) ?? 0;
                      final msg = await context.read<AppStore>().confirmEntryByBarcode(
                            barcode: _barcode,
                            quantity: qty,
                          );
                      if (!context.mounted) return;
                      if (msg != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                        return;
                      }
                      Navigator.of(context).pop(match.nome);
                    } finally {
                      if (context.mounted) setState(() => _busy = false);
                    }
                  },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _code.dispose();
    _qty.dispose();
    super.dispose();
  }
}
