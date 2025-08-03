// lib/screens/ocr_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../viewmodels/ocr_viewmodel.dart';
import '../viewmodels/models_viewmodel.dart'; // Import ModelsViewModel

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  _OCRScreenState createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;

  // --- REMOVED: State variable is now in the ViewModel ---
  // String? _selectedModel;

  // --- UPDATED: Simplified method ---
  Future<void> _pickImageAndAnalyze() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        // The ViewModel already knows the selected model.
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
    // Watch the OcrViewModel for state changes.
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
            _buildImageDisplay(),
            const SizedBox(height: 20),
            // The builder method now takes the ViewModel as a parameter
            _buildModelSelector(ocrViewModel),
            const SizedBox(height: 20),
            _buildScanButton(ocrViewModel.isLoading),
            const SizedBox(height: 30),
            _buildResultDisplay(ocrViewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child:
          _image == null
              ? const Center(child: Text("Point camera at text to read."))
              : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
    );
  }

  // --- UPDATED WIDGET: Now driven by OcrViewModel state ---
  Widget _buildModelSelector(OcrViewModel ocrViewModel) {
    final modelsViewModel = context.watch<ModelsViewModel>();
    final ocrModels = modelsViewModel.models['OCR'] ?? [];

    if (modelsViewModel.isLoading) {
      return const Center(child: Text("Loading AI models..."));
    }
    if (modelsViewModel.errorMessage != null) {
      return Center(
        child: Text(
          "Error: ${modelsViewModel.errorMessage}",
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (ocrModels.isEmpty) {
      return const Center(child: Text("No OCR models available from server."));
    }

    // Set the default model in the ViewModel if it's not set and models are available
    if (ocrViewModel.selectedModel == null && ocrModels.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ocrViewModel.setModel(ocrModels.first);
      });
    }

    return DropdownButtonFormField<String>(
      value: ocrViewModel.selectedModel,
      decoration: const InputDecoration(
        labelText: 'AI Model',
        border: OutlineInputBorder(),
      ),
      items:
          ocrModels.map((model) {
            return DropdownMenuItem(value: model, child: Text(model));
          }).toList(),
      // Call the ViewModel's method on change
      onChanged: (value) => ocrViewModel.setModel(value),
    );
  }

  Widget _buildScanButton(bool isLoading) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : _pickImageAndAnalyze,
      icon: const Icon(Icons.camera_enhance),
      label: const Text("Scan Text"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildResultDisplay(OcrViewModel ocrViewModel) {
    if (ocrViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (ocrViewModel.errorMessage != null) {
      return Center(
        child: Text(
          "Error: ${ocrViewModel.errorMessage}",
          style: const TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (ocrViewModel.ocrResult != null) {
      final result = ocrViewModel.ocrResult!;
      final processingTime = result.processingTime.toStringAsFixed(2);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            SelectableText(
              result.text.isEmpty ? "No text found." : result.text,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),
            Text(
              "Processed in $processingTime seconds",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
