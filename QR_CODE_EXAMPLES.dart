// EXEMPLO: Como usar o QrCodeField em outras telas

import 'package:acai_stock/widgets/qr_code_field.dart';
import 'package:flutter/material.dart';

/// Exemplo 1: Em um formulário de busca de produtos
class SearchProductScreen extends StatefulWidget {
  @override
  State<SearchProductScreen> createState() => _SearchProductScreenState();
}

class _SearchProductScreenState extends State<SearchProductScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleScannedCode(String code) {
    // Implementar busca por código
    print('Buscando produto com código: $code');
    // store.searchProductByBarcode(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Produto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            QrCodeField(
              label: 'Código do Produto',
              controller: _searchController,
              hint: 'Digite ou escanear código QR',
              onScanned: _handleScannedCode,
            ),
            const SizedBox(height: 16),
            // Resultado da busca aqui
          ],
        ),
      ),
    );
  }
}

/// Exemplo 2: Transferência de estoque entre galpões
class StockTransferScreen extends StatefulWidget {
  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  final _sourceProductController = TextEditingController();
  final _destProductController = TextEditingController();

  @override
  void dispose() {
    _sourceProductController.dispose();
    _destProductController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transferência de Estoque')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Produto de Origem', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            QrCodeField(
              label: 'Código Origem',
              controller: _sourceProductController,
              onScanned: (code) {
                print('Produto origem: $code');
              },
            ),
            const SizedBox(height: 24),
            const Text('Produto de Destino', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            QrCodeField(
              label: 'Código Destino',
              controller: _destProductController,
              onScanned: (code) {
                print('Produto destino: $code');
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Executar transferência
                print('Transferindo de ${_sourceProductController.text} para ${_destProductController.text}');
              },
              child: const Text('Confirmar Transferência'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exemplo 3: Validação de lote com QR
class LotValidationScreen extends StatefulWidget {
  @override
  State<LotValidationScreen> createState() => _LotValidationScreenState();
}

class _LotValidationScreenState extends State<LotValidationScreen> {
  final _lotController = TextEditingController();
  final List<String> _scannedCodes = [];

  @override
  void dispose() {
    _lotController.dispose();
    super.dispose();
  }

  void _addScannedCode(String code) {
    setState(() {
      _scannedCodes.add(code);
    });
    _lotController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Produto $code adicionado ao lote')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validação de Lote')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            QrCodeField(
              label: 'Produtos do Lote',
              controller: _lotController,
              hint: 'Escanear produtos',
              onScanned: _addScannedCode,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _scannedCodes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Produto ${_scannedCodes[index]}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() => _scannedCodes.removeAt(index));
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                print('Lote validado com ${_scannedCodes.length} produtos');
              },
              child: Text('Validar (${_scannedCodes.length} itens)'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exemplo 4: Integração com Provider para estado global
/*
class GlobalQrProvider extends ChangeNotifier {
  String? _lastScannedCode;
  
  String? get lastScannedCode => _lastScannedCode;
  
  void setScannedCode(String code) {
    _lastScannedCode = code;
    notifyListeners();
  }
}

// Uso em widget:
Consumer<GlobalQrProvider>(
  builder: (context, provider, _) {
    return QrCodeField(
      label: 'Código',
      controller: _controller,
      onScanned: (code) {
        provider.setScannedCode(code);
      },
    );
  },
)
*/
