import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'screens/auth_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..initialize(),
      child: const VoiceExpenseApp(),
    ),
  );
}

class VoiceExpenseApp extends StatelessWidget {
  const VoiceExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Expense Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF4CAF50),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF4CAF50),
          surface: const Color(0xFF16213E),
          error: Colors.redAccent,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
              SizedBox(height: 24),
              Text(
                'Đang khởi động...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return const AuthScreen();
  }
}
