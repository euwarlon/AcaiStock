import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerProvider extends ChangeNotifier {
  final MobileScannerController _controller = MobileScannerController();

  MobileScannerController get controller => _controller;

  String? _scannedCode;
  String? get scannedCode => _scannedCode;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  void setScannedCode(String code) {
    _scannedCode = code;
    notifyListeners();
  }

  void clearScannedCode() {
    _scannedCode = null;
    notifyListeners();
  }

  void setIsScanning(bool value) {
    _isScanning = value;
    notifyListeners();
  }

  void toggleFlash() async {
    await _controller.toggleTorch();
    notifyListeners();
  }

  void switchCamera() async {
    await _controller.switchCamera();
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
