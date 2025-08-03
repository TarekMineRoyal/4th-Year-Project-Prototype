// lib/screens/ocr_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../viewmodels/ocr_viewmodel.dart';
import '../viewmodels/models_viewmodel.dart';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  _OCRScreenState createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;

  Future<void> _pickImageAndAnalyze() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        // The result will be announced automatically by the live region.
        context.read<OcrViewModel>().fetchOcrResult(_image!.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to pick image: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
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
            _buildScanButton(ocrViewModel.isLoading),
            const SizedBox(height: 24),
            _buildModelSelector(ocrViewModel),
            const SizedBox(height: 30),
            _buildResultDisplay(ocrViewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Semantics(
      label:
          _image == null
              ? "No image selected. Use the scan button below to take a picture of text."
              : "A preview of the image to be scanned for text.",
      child: Container(
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
      ),
    );
  }

  Widget _buildScanButton(bool isLoading) {
    return Semantics(
      label:
          "Scan Text Button. Double tap to activate the camera and read text.",
      button: true,
      excludeSemantics: true,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _pickImageAndAnalyze,
        icon: const Icon(Icons.camera_enhance),
        label: const Text("Scan Text"),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildModelSelector(OcrViewModel ocrViewModel) {
    final modelsViewModel = context.watch<ModelsViewModel>();
    final ocrModels = modelsViewModel.models['OCR'] ?? [];

    if (modelsViewModel.isLoading || ocrModels.isEmpty) {
      return const SizedBox.shrink(); // Don't show if loading or no models
    }

    if (ocrViewModel.selectedModel == null && ocrModels.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ocrViewModel.setModel(ocrModels.first);
      });
    }

    return Semantics(
      label:
          "Select AI Model for text recognition. Current model is ${ocrViewModel.selectedModel ?? 'not selected'}.",
      child: DropdownButtonFormField<String>(
        value: ocrViewModel.selectedModel,
        decoration: const InputDecoration(
          labelText: 'AI Model',
          border: OutlineInputBorder(),
        ),
        items:
            ocrModels
                .map(
                  (model) => DropdownMenuItem(value: model, child: Text(model)),
                )
                .toList(),
        onChanged: (value) => ocrViewModel.setModel(value),
      ),
    );
  }

  Widget _buildResultDisplay(OcrViewModel ocrViewModel) {
    if (ocrViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    String? announcement;
    if (ocrViewModel.errorMessage != null) {
      announcement = "Error: ${ocrViewModel.errorMessage}";
    } else if (ocrViewModel.ocrResult != null) {
      announcement =
          ocrViewModel.ocrResult!.text.isEmpty
              ? "No text was found in the image."
              : "Detected text: ${ocrViewModel.ocrResult!.text}";
    }

    // This Semantics widget is key. 'liveRegion: true' makes screen readers
    // automatically announce the content as soon as it appears or changes.
    return Semantics(
      liveRegion: true,
      child:
          announcement == null
              ? const SizedBox.shrink()
              : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      ocrViewModel.errorMessage != null
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  announcement,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        ocrViewModel.errorMessage != null
                            ? Colors.red
                            : Colors.black87,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
    );
  }
}
