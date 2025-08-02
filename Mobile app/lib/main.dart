// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import viewmodels
import 'viewmodels/session_viewmodel.dart';
import 'viewmodels/vqa_viewmodel.dart';
import 'viewmodels/ocr_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'screens/home_screen.dart';

// The main entry point of the application.
void main() async {
  // WidgetsFlutterBinding.ensureInitialized() is required to use platform services
  // like SharedPreferences before runApp() is called.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VqaViewModel()),
        ChangeNotifierProvider(create: (_) => OcrViewModel()),
        ChangeNotifierProvider(create: (_) => SessionViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
      ],
      child: MaterialApp(
        title: 'AuraLnes',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // Set your HomePage as the entry point
        home: const HomePage(),
      ),
    );
  }
}
