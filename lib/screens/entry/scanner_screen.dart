import 'package:acai_stock/providers/qr_scanner_provider.dart';
import 'package:acai_stock/screens/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QrScannerProvider(),
      child: const QrScannerScreen(),
    );
  }
}
