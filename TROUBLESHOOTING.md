# 🔧 Troubleshooting e Configuração - Leitor de QR Code

## ⚙️ Configuração Rápida

### 1. Se o Scanner Não Abre

**Problema:** Erro ao tentar abrir a tela de scanner

**Soluções:**
```bash
# Limpar cache e reinstalar
flutter clean
flutter pub get
flutter run

# Se ainda não funcionar, verificar dependências
flutter pub outdated
flutter pub upgrade
```

### 2. Permissão de Câmera Não Funciona

**Android:**
```bash
# Verificar se AndroidManifest.xml tem a permissão
grep -n "CAMERA" android/app/src/main/AndroidManifest.xml

# Deve ter:
# <uses-permission android:name="android.permission.CAMERA"/>
```

**iOS:**
```bash
# Verificar Info.plist
grep -n "NSCameraUsageDescription" ios/Runner/Info.plist

# Deve ter uma descrição como:
# <key>NSCameraUsageDescription</key>
# <string>Este app precisa acessar sua câmera...</string>
```

### 3. Scanner Muito Lento/Travando

**Causa:** Câmera sobrecarregada

**Soluções:**
- Desabilitar flash se estiver ligado
- Reduzir resolução da câmera (em `qr_scanner_screen.dart` se necessário)
- Fechar outros apps que usam câmera
- Reiniciar o dispositivo

### 4. Não Reconhece Certos Códigos QR

**Verificar:**
- Qualidade do código (nitidez, contraste)
- Distância adequada (15-20cm)
- Iluminação suficiente
- Tentar trocar câmera (frontal/traseira)

---

## 🐛 Debugging

### Ativar logs de debug

**Em `qr_scanner_screen.dart`**, adicione:
```dart
@override
void initState() {
  super.initState();
  debugPrint('QR Scanner inicializado');
  _requestCameraPermission();
}
```

### Verificar estado do scanner

**Em `qr_scanner_provider.dart`**:
```dart
void setScannedCode(String code) {
  debugPrint('Código lido: $code');
  _scannedCode = code;
  notifyListeners();
}
```

### Logs de permissão

```dart
Future<void> _requestCameraPermission() async {
  debugPrint('Solicitando permissão de câmera...');
  final status = await Permission.camera.request();
  debugPrint('Status: ${status.isDenied} / ${status.isGranted}');
  setState(() {
    _hasPermission = status.isGranted;
    _isInitialized = true;
  });
}
```

---

## 📊 Performance

### Métricas Esperadas

| Métrica | Valor Esperado |
|---------|---|
| Tempo para abrir scanner | < 1s |
| Tempo para ler QR | < 2s |
| Uso de memória | < 50MB |
| Taxa de acurácia | > 95% |

### Otimizações Possíveis

```dart
// Reduzir qualidade da câmera se necessário
MobileScanner(
  controller: provider.controller,
  // autoStart: true,
  // formats: [BarcodeFormat.qrCode], // Apenas QR codes
  onDetect: (detection) { ... },
)
```

---

## 🔐 Segurança

### Validação de Código

Adicione validação antes de usar o código:

```dart
void _handleScannedCode(String code) {
  // Validar formato
  if (code.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código inválido')),
    );
    return;
  }
  
  // Validar caracteres
  if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(code)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código contém caracteres inválidos')),
    );
    return;
  }
  
  // Usar código validado
  Navigator.of(context).pop(code);
}
```

### Limpeza de Dados

Certificar que o provider é descartado corretamente:

```dart
@override
void dispose() {
  _controller.dispose(); // ✅ Importante
  super.dispose();
}
```

---

## 🌐 Compatibilidade

### Versões Mínimas

| Platform | Versão |
|----------|--------|
| Android | 5.0+ (API 21+) |
| iOS | 11.0+ |
| Flutter | 3.5.0+ |
| Dart | 3.5.0+ |

### Formatos Suportados

- ✅ QR Code
- ✅ EAN 13
- ✅ EAN 8
- ✅ Code 39
- ✅ Code 128
- ✅ Codabar
- ✅ UPC-A
- ✅ UPC-E

---

## 📱 Testes em Devices Reais

### Android
```bash
# Build e instalar
flutter build apk
flutter install

# Ou direto
flutter run -d <device_id>
```

### iOS
```bash
# Abrir no Xcode para configurar assinatura
open ios/Runner.xcworkspace

# Ou via CLI
flutter run -d <device_id>
```

---

## 💾 Backup e Restore

### Se precisar reverter as mudanças

```bash
# Ver histórico
git log --oneline lib/providers/qr_scanner_provider.dart

# Reverter arquivo
git checkout HEAD~1 lib/screens/products/product_editor_screen.dart
```

---

## 📞 Recursos Úteis

- **mobile_scanner docs:** https://pub.dev/packages/mobile_scanner
- **permission_handler docs:** https://pub.dev/packages/permission_handler
- **Flutter camera docs:** https://docs.flutter.dev/packages-and-plugins/using-plugins

---

## ✅ Checklist de Deployment

- [ ] Testar em Android real
- [ ] Testar em iOS real
- [ ] Verificar permissões em ambos os platforms
- [ ] Testar com vários tipos de código
- [ ] Verificar consumo de bateria
- [ ] Documentar limites de taxa de leitura
- [ ] Preparar release notes

---

**Última atualização:** 20 de maio de 2026
