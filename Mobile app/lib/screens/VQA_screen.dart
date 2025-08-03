// lib/screens/vqa_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../viewmodels/vqa_viewmodel.dart';
import '../viewmodels/models_viewmodel.dart';

class VQAScreen extends StatefulWidget {
  const VQAScreen({super.key});

  @override
  State<VQAScreen> createState() => _VQAScreenState();
}

class _VQAScreenState extends State<VQAScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _image;

  final List<String> _analysisModes = ['Brief', 'Thorough'];

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        // This is a more reliable way to announce changes.
        // We will let the result display handle its own announcements.
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to pick image: $e")));
    }
  }

  void _getAnswer() {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first.")),
      );
      return;
    }
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a question.")));
      return;
    }

    context.read<VqaViewModel>().fetchVqaResult(
      _image!.path,
      _questionController.text,
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vqaViewModel = context.watch<VqaViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Visual Question Answering")),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildModelSelectors(vqaViewModel),
              const SizedBox(height: 24),
              _buildQuestionInput(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 30),
              _buildResultDisplay(vqaViewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label:
              _image == null
                  ? "Step 1: Image Preview. No image selected."
                  : "Step 1: Image Preview. An image is selected.",
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                _image == null
                    ? const Center(child: Text("No image selected"))
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.camera_alt),
          label: const Text("Take Picture"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildModelSelectors(VqaViewModel vqaViewModel) {
    final modelsViewModel = context.watch<ModelsViewModel>();
    final vqaModels = modelsViewModel.models['VQA'] ?? [];

    if (modelsViewModel.isLoading) {
      return const Center(child: Text("Loading AI models..."));
    }
    if (vqaModels.isEmpty) {
      return const Center(child: Text("No VQA models available from server."));
    }

    if (vqaViewModel.selectedModel == null && vqaModels.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vqaViewModel.setModel(vqaModels.first);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: "Step 2: AI Model Selection.",
          child: DropdownButtonFormField<String>(
            value: vqaViewModel.selectedModel,
            decoration: const InputDecoration(
              labelText: 'AI Model',
              border: OutlineInputBorder(),
            ),
            items:
                vqaModels
                    .map(
                      (model) =>
                          DropdownMenuItem(value: model, child: Text(model)),
                    )
                    .toList(),
            onChanged: (value) => vqaViewModel.setModel(value),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: vqaViewModel.selectedMode?.replaceFirst(
            vqaViewModel.selectedMode![0],
            vqaViewModel.selectedMode![0].toUpperCase(),
          ),
          decoration: const InputDecoration(
            labelText: 'Analysis Mode',
            border: OutlineInputBorder(),
          ),
          items:
              _analysisModes
                  .map(
                    (mode) => DropdownMenuItem(value: mode, child: Text(mode)),
                  )
                  .toList(),
          onChanged: (value) => vqaViewModel.setMode(value?.toLowerCase()),
        ),
      ],
    );
  }

  Widget _buildQuestionInput() {
    return Semantics(
      label: "Step 3: Ask a question.",
      child: TextField(
        controller: _questionController,
        decoration: const InputDecoration(
          labelText: "Ask a question about the scene",
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isLoading = context.select((VqaViewModel vm) => vm.isLoading);
    return Semantics(
      label: "Step 4: Get the answer.",
      button: true,
      excludeSemantics: true,
      child: ElevatedButton(
        onPressed: isLoading ? null : _getAnswer,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        child: const Text("Get Answer"),
      ),
    );
  }

  Widget _buildResultDisplay(VqaViewModel vqaViewModel) {
    if (vqaViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    String? announcement;
    if (vqaViewModel.errorMessage != null) {
      announcement = "Error: ${vqaViewModel.errorMessage}";
    } else if (vqaViewModel.vqaResult != null) {
      announcement = "Answer: ${vqaViewModel.vqaResult!.answer}";
    }

    return Semantics(
      liveRegion: true,
      child:
          announcement == null
              ? const SizedBox.shrink()
              : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      vqaViewModel.errorMessage != null
                          ? Colors.red.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  announcement,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        vqaViewModel.errorMessage != null
                            ? Colors.red
                            : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
    );
  }
}
