import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <--- IMPORTANTE: Import da tradução
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- INICIALIZAÇÃO DO BANCO PARA DESKTOP ---
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // INICIALIZA AS NOTIFICAÇÕES
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Gado',
      debugShowCheckedModeBanner: false,
      
      // --- CONFIGURAÇÃO DE IDIOMA (NOVO) ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Define Português do Brasil
      ],
      // -------------------------------------

      // TEMA CLARO (Padrão)
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),

      // TEMA ESCURO (Economia de Bateria - OLED)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        primaryColor: Colors.green[700],
        scaffoldBackgroundColor: const Color(0xFF121212), // Preto suave
        cardColor: const Color(0xFF1E1E1E), // Cinza escuro para cartões
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[900],
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white
        )
      ),
      
      // O app segue a configuração do sistema do celular automaticamente
      themeMode: ThemeMode.system, 

      home: const HomeScreen(),
    );
  }
}