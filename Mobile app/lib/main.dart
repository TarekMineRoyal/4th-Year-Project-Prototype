// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import services and viewmodels
import 'services/api_service.dart';
import 'viewmodels/session_viewmodel.dart';
import 'viewmodels/vqa_viewmodel.dart';
import 'viewmodels/ocr_viewmodel.dart';
import 'viewmodels/video_analysis_viewmodel.dart';
import 'screens/home_screen.dart';

// The main entry point of the application.
void main() async {
  // WidgetsFlutterBinding.ensureInitialized() is required to use platform services
  // like SharedPreferences before runApp() is called.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the ApiService to handle the one-time user ID setup.
  final ApiService apiService = ApiService();

  try {
    // This will either fetch a new user ID from the backend and save it,
    // or do nothing if one is already stored locally.
    // This must complete before the app starts to ensure the ID is available
    // for any subsequent API calls.
    await apiService.initializeUser();
  } catch (e) {
    // If user initialization fails (e.g., no network on first launch),
    // we can decide how to handle it. For now, we'll print an error.
    // In a production app, you might show an error message and exit,
    // or allow the app to run in a limited offline mode.
    print(
      "CRITICAL: Failed to initialize user ID. Some features may not work.",
    );
    print(e);
  }

  // Once initialization is done, run the app as usual.
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VqaViewModel()),
        ChangeNotifierProvider(create: (_) => OcrViewModel()),
        ChangeNotifierProvider(create: (_) => VideoAnalysisViewModel()),
        ChangeNotifierProvider(create: (_) => SessionViewModel()),
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
