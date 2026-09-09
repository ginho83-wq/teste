import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Teste',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),

        // ==========================================================
        // TIPOGRAFIA GLOBAL
        // ==========================================================
        textTheme: const TextTheme(

          // Texto principal
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.5,
          ),

          // Texto normal
          bodyMedium: TextStyle(
            fontSize: 15,
            height: 1.5,
          ),

          // Texto secundário
          bodySmall: TextStyle(
            fontSize: 14,
            height: 1.4,
          ),

          // Títulos grandes
          titleLarge: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),

          // Títulos médios
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),

          // Títulos pequenos
          titleSmall: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),

          // Texto dos botões e controles
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),

          // Labels menores
          labelMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),

          labelSmall: TextStyle(
            fontSize: 13,
            height: 1.2,
          ),
        ),

        // ==========================================================
        // CAMPOS DE TEXTO
        // ==========================================================
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(
            fontSize: 16,
          ),
          floatingLabelStyle: TextStyle(
            fontSize: 16,
          ),
          hintStyle: TextStyle(
            fontSize: 16,
          ),
          helperStyle: TextStyle(
            fontSize: 14,
          ),
          errorStyle: TextStyle(
            fontSize: 14,
          ),
        ),

        // ==========================================================
        // BOTÕES
        // ==========================================================
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // ==========================================================
        // APP BAR
        // ==========================================================
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      routerConfig: appRouter,
    );
  }
}

