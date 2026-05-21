import 'package:acai_stock/providers/qr_scanner_provider.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _hasPermission = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
      _isInitialized = true;
    });
  }

  void _handleScannedCode(String? code, QrScannerProvider provider) {
    if (code != null && code.isNotEmpty) {
      provider.setScannedCode(code);
      // Voltar para a tela anterior com o código lido
      Navigator.of(context).pop(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ler Código QR'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<QrScannerProvider>(
        builder: (context, provider, _) {
          if (!_isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!_hasPermission) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Permissão de câmera necessária',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Este app precisa acessar sua câmera para ler códigos QR',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _requestCameraPermission,
                    child: const Text('Conceder Permissão'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              MobileScanner(
                controller: provider.controller,
                onDetect: (detection) {
                  final barcode = detection.barcodes.firstOrNull;
                  if (barcode?.rawValue != null) {
                    _handleScannedCode(barcode!.rawValue, provider);
                  }
                },
              ),
              // Overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Opacity(
                  opacity: 0.3,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Caixas nas cantos
              Positioned(
                top: MediaQuery.of(context).size.height / 2 - 130,
                left: MediaQuery.of(context).size.width / 2 - 130,
                child: _buildCornerBorder(TopLeft: true),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height / 2 - 130,
                right: MediaQuery.of(context).size.width / 2 - 130,
                child: _buildCornerBorder(TopRight: true),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height / 2 - 130,
                left: MediaQuery.of(context).size.width / 2 - 130,
                child: _buildCornerBorder(BottomLeft: true),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height / 2 - 130,
                right: MediaQuery.of(context).size.width / 2 - 130,
                child: _buildCornerBorder(BottomRight: true),
              ),
              // Controles na parte inferior
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text(
                      'Aproxime o código QR para ler',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.white.withOpacity(0.8),
                          onPressed: provider.toggleFlash,
                          tooltip: 'Ligar Lanterna',
                          child: const Icon(
                            Icons.flash_on,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 16),
                        FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.white.withOpacity(0.8),
                          onPressed: provider.switchCamera,
                          tooltip: 'Trocar Câmera',
                          child: const Icon(
                            Icons.flip_camera_ios,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCornerBorder({
    bool TopLeft = false,
    bool TopRight = false,
    bool BottomLeft = false,
    bool BottomRight = false,
  }) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: TopLeft || TopRight ? Colors.white : Colors.transparent,
            width: 3,
          ),
          left: BorderSide(
            color: TopLeft || BottomLeft ? Colors.white : Colors.transparent,
            width: 3,
          ),
          right: BorderSide(
            color: TopRight || BottomRight ? Colors.white : Colors.transparent,
            width: 3,
          ),
          bottom: BorderSide(
            color: BottomLeft || BottomRight ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}
