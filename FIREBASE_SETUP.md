# Configuração Firebase - Açaí Stock

## Passo 1: Criar Projeto no Firebase Console

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Clique em "Adicionar projeto"
3. Nome: `acai-stock` (ou seu preferido)
4. Continue com as configurações padrão
5. Aguarde a criação do projeto

## Passo 2: Ativar Autenticação por Email

1. No Firebase Console, vá para **Authentication**
2. Clique em "Get Started"
3. Selecione **Email/Password**
4. Ative a opção "Email/Password"
5. Clique em "Save"

## Passo 3: Configurar Firebase para Android

1. No Firebase Console, clique em **Configurações do Projeto**
2. Vá para **Suas aplicações** → **Android**
3. Registre seu app:
   - Nome do pacote: `com.example.acaistock` (ou seu pacote)
   - Nome do app: `Açaí Stock` (opcional)
4. Baixe o arquivo `google-services.json`
5. Coloque em: `android/app/google-services.json` ✅ (já configurado)
6. **Plugin Gradle Google Services** (já configurado):
   - `android/build.gradle`: adicionado `com.google.gms:google-services:4.4.4` em buildscript
   - `android/app/build.gradle`: adicionado plugin `com.google.gms.google-services`
   - Dependências Firebase BoM adicionadas

Sincronize seu projeto Android com os arquivos Gradle.

## Passo 4: Configurar Firebase para iOS

1. No Firebase Console, clique em **+Adicionar aplicativo** → **iOS**
2. Registre seu app:
   - Bundle ID: `com.example.acaistock` (ou seu bundle)
   - Nome do app: `Açaí Stock` (opcional)
3. Baixe o arquivo `GoogleService-Info.plist`
4. Abra seu projeto Xcode: `ios/Runner.xcworkspace`
5. Arraste o `GoogleService-Info.plist` para a pasta `Runner`
6. Marque a opção "Copy if needed"

## Passo 5: Atualizar firebase_options.dart

1. Abra seu projeto no Firebase Console
2. Vá para **Configurações do Projeto**
3. Copie as credenciais para cada plataforma:

```dart
// Para WEB:
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'SEU_WEB_API_KEY',
  appId: 'SEU_WEB_APP_ID',
  messagingSenderId: 'SEU_WEB_MESSAGING_SENDER_ID',
  projectId: 'seu-projeto-id',
  authDomain: 'seu-projeto-id.firebaseapp.com',
  storageBucket: 'seu-projeto-id.appspot.com',
);

// Para Android:
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'SEU_ANDROID_API_KEY',
  appId: 'SEU_ANDROID_APP_ID',
  messagingSenderId: 'SEU_ANDROID_MESSAGING_SENDER_ID',
  projectId: 'seu-projeto-id',
  storageBucket: 'seu-projeto-id.appspot.com',
);

// E assim por diante para iOS, macOS, Windows...
```

## Passo 6: Executar o App

```bash
# Web
flutter run -d chrome

# Android
flutter run -d emulator-5554

# iOS
flutter run -d iphone
```

## Recursos

- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [FlutterFire](https://firebase.flutter.dev/)
- [Email/Password Authentication](https://firebase.flutter.dev/docs/auth/usage/)

## Funcionalidades Firebase Implementadas

✅ Autenticação por Email/Senha
✅ Criação de Conta
✅ Recuperação de Senha (link enviado por email)
✅ Logout

## Recuperação de Senha

1. Usuário clica em "Esqueceu sua senha?"
2. Insere seu email
3. Firebase envia link de recuperação
4. Clicando no link, usuário define nova senha
5. Logout automático após sucesso

## Suporte

Para problemas de configuração, verifique:
- Google Play Services instalado (Android)
- Bundle ID correto (iOS)
- Credenciais Firebase corretas em firebase_options.dart
