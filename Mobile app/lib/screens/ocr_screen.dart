// lib/screens/ocr_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../viewmodels/ocr_viewmodel.dart';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  _OCRScreenState createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;

  // --- Local UI Methods ---

  Future<void> _pickImageAndAnalyze() async {
    // This logic is purely for the UI, so it stays in the View.
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        // Immediately call the ViewModel to analyze the new image
        // Use context.read to call the method without rebuilding.
        context.read<OcrViewModel>().fetchOcrResult(_image!.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to pick image: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use context.watch to listen for state changes from the ViewModel.
    // This widget will rebuild whenever notifyListeners() is called.
    final ocrViewModel = context.watch<OcrViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Text Reader (OCR)"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Image Display ---
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  _image == null
                      ? const Center(
                        child: Text("Point camera at text to read."),
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
            ),
            const SizedBox(height: 20),

            // --- Action Button ---
            ElevatedButton.icon(
              onPressed:
                  ocrViewModel.isLoading
                      ? null
                      : _pickImageAndAnalyze, // Disable while loading
              icon: const Icon(Icons.camera_enhance),
              label: const Text("Scan Text"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // --- Reactive Result Display ---
            // This part of the UI rebuilds based on the ViewModel's state.
            if (ocrViewModel.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (ocrViewModel.errorMessage != null)
              Center(
                child: Text(
                  "Error: ${ocrViewModel.errorMessage}",
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
            else if (ocrViewModel.ocrResult != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  // Use SelectableText to allow copying
                  ocrViewModel.ocrResult!.text.isEmpty
                      ? "No text found."
                      : ocrViewModel.ocrResult!.text,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.left,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
