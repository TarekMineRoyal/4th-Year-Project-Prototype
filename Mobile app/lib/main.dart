// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 1. Import all your ViewModels and the HomePage
import 'viewmodels/vqa_viewmodel.dart';
import 'viewmodels/ocr_viewmodel.dart';
import 'viewmodels/video_analysis_viewmodel.dart';
import 'screens/home_screen.dart';

void main() {
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
      ],
      child: MaterialApp(
        title: 'AI Visual Assistant',
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
