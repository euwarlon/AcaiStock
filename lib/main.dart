import 'package:acai_stock/providers/app_store.dart';
import 'package:acai_stock/screens/root_flow.dart';
import 'package:acai_stock/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Falha ao inicializar Firebase: $e. Continuando sem sincronização.');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStore(),
      child: const AcaiStockApp(),
    ),
  );
}

class AcaiStockApp extends StatelessWidget {
  const AcaiStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Açaí Stock',
      themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const RootFlow(),
    );
  }
}
