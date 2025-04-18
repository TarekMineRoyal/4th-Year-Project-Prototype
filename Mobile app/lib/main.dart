import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ImageSelectorApp());
}

class ImageSelectorApp extends StatelessWidget {
  const ImageSelectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Analyzer',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomePage(),
    );
  }
}
