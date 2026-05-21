import 'package:acai_stock/providers/app_store.dart';
import 'package:acai_stock/screens/root_flow.dart';
import 'package:acai_stock/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  SupabaseClient? supabaseClient;
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      supabaseClient = Supabase.instance.client;
    } catch (e) {
      debugPrint(
          'Falha ao inicializar Supabase: $e. Continuando sem sincronização.');
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStore(
        supabaseClient: supabaseClient,
      ),
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
