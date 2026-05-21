# Leitor de QR Code - Guia de Uso

## Funcionalidades Implementadas

O app agora possui um **leitor de QR code** integrado ao editor de produtos para facilitar a leitura de códigos de barras.

### Como Usar

#### 1. **Adicionar ou Editar um Produto**
- Vá para a tela de produtos
- Clique em "Novo Produto" (ícone +) ou selecione um produto existente para editar

#### 2. **Ler Código QR**
- No formulário de edição, você verá um campo "Barcode" com um botão de câmera **📷** ao lado
- Clique no ícone da câmera para abrir o leitor de QR code
- O app solicitará permissão para acessar a câmera (primeira vez)

#### 3. **Funcionamento do Scanner**
- **Enquadre o código QR** na área marcada na tela
- O código será **lido automaticamente** quando reconhecido
- O código aparecerá no campo "Barcode" e você voltará ao formulário
- Um **toast (mensagem)** confirma o código lido

### Controles Disponíveis no Scanner

| Ícone | Função |
|-------|--------|
| ⚡ (Flash) | Ligar/desligar lanterna para códigos em ambientes escuros |
| 🔄 (Camera) | Trocar entre câmera frontal e traseira |

### Permissões Necessárias

**Android:**
- ✅ Permissão de câmera configurada no `AndroidManifest.xml`

**iOS:**
- ✅ Descrição de uso da câmera no `Info.plist`
- O app solicitará permissão na primeira utilização

### Arquivos Modificados

1. **pubspec.yaml** - Adicionadas dependências:
   - `mobile_scanner: ^4.0.1` (leitor de QR code)
   - `permission_handler: ^11.4.0` (gerenciamento de permissões)

2. **lib/providers/qr_scanner_provider.dart** - Novo arquivo
   - Provider para gerenciar o estado do scanner

3. **lib/screens/qr_scanner_screen.dart** - Novo arquivo
   - Tela completa do leitor de QR code

4. **lib/screens/products/product_editor_screen.dart** - Modificado
   - Adicionado botão para ler QR code
   - Integração com o scanner

5. **android/app/src/main/AndroidManifest.xml** - Modificado
   - Permissão de câmera adicionada

6. **ios/Runner/Info.plist** - Modificado
   - Descrição de uso da câmera para iOS

### Próximas Melhorias

- [ ] Adicionar histórico de códigos lidos
- [ ] Suporte a diferentes formatos de código de barras
- [ ] Validação de código antes de salvar
- [ ] Buscar produto pelo código lido

