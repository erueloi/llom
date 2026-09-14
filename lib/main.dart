import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/library_provider.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LlomApp());
}

class LlomApp extends StatelessWidget {
  final Widget? home;

  const LlomApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LibraryProvider>(
          create: (_) => LibraryProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Llom',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: home ?? const AuthGate(),
      ),
    );
  }
}
