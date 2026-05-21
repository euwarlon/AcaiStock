import 'package:acai_stock/screens/entry/manual_entry_screen.dart';
import 'package:acai_stock/widgets/acai_button.dart';
import 'package:flutter/material.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool flashOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Produto')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E174A), Color(0xFF120A1E)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 64),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 260,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: flashOn ? Colors.amberAccent : Colors.white70,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: flashOn ? Colors.amber : Colors.black54,
                      ),
                      onPressed: () => setState(() => flashOn = !flashOn),
                      icon: Icon(flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Text(
                      flashOn ? 'Flash ligado' : 'Flash desligado',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AcaiButton(
              text: 'Digitar Código',
              onPressed: () async {
                final result = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => const ManualEntryScreen()),
                );
                if (context.mounted && result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Entrada confirmada para: $result')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
