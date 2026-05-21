import 'package:acai_stock/providers/qr_scanner_provider.dart';
import 'package:acai_stock/screens/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget para ler código QR e preenchimento automático de um campo
/// 
/// Exemplo de uso:
/// ```dart
/// QrCodeField(
///   label: 'Barcode',
///   controller: _barcodeController,
///   onScanned: (code) {
///     print('Código lido: $code');
///   },
/// )
/// ```
class QrCodeField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final Function(String)? onScanned;
  final String? hint;
  final TextInputType keyboardType;
  final bool readOnly;

  const QrCodeField({
    super.key,
    required this.label,
    required this.controller,
    this.onScanned,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
  });

  @override
  State<QrCodeField> createState() => _QrCodeFieldState();
}

class _QrCodeFieldState extends State<QrCodeField> {
  Future<void> _openQrScanner() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => QrScannerProvider(),
          child: const QrScannerScreen(),
        ),
      ),
    );

    if (result != null && result is String && mounted) {
      widget.controller.text = result;
      widget.onScanned?.call(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código lido: $result'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            readOnly: widget.readOnly,
            keyboardType: widget.keyboardType,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: IconButton.filled(
            onPressed: _openQrScanner,
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Ler código QR',
          ),
        ),
      ],
    );
  }
}
