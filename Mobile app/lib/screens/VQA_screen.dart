// lib/screens/vqa_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../viewmodels/vqa_viewmodel.dart';
import '../viewmodels/models_viewmodel.dart'; // Import ModelsViewModel

class VQAScreen extends StatefulWidget {
  const VQAScreen({super.key});

  @override
  State<VQAScreen> createState() => _VQAScreenState();
}

class _VQAScreenState extends State<VQAScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _image;

  // --- REMOVED: State variables are now in the ViewModel ---
  // String? _selectedModel;
  // String _selectedMode = 'Brief';
  final List<String> _analysisModes = ['Brief', 'Thorough'];

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to pick image: $e")));
    }
  }

  // --- UPDATED: Simplified method ---
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

    // The ViewModel already knows the selected model and mode.
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
    // Watch the VqaViewModel for state changes.
    final vqaViewModel = context.watch<VqaViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Visual Question Answering"),
        backgroundColor: Colors.blue,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              // The building of model selectors now takes the ViewModel as a parameter
              _buildModelSelectors(vqaViewModel),
              const SizedBox(height: 24),
              _buildQuestionInput(),
              const SizedBox(height: 16),
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
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              _image == null
                  ? const Center(child: Text("No image selected."))
                  : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, fit: BoxFit.cover),
                  ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.camera_alt),
          label: const Text("Take Picture"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  // --- UPDATED WIDGET: Now driven by VqaViewModel state ---
  Widget _buildModelSelectors(VqaViewModel vqaViewModel) {
    final modelsViewModel = context.watch<ModelsViewModel>();
    final vqaModels = modelsViewModel.models['VQA'] ?? [];

    if (modelsViewModel.isLoading) {
      return const Center(child: Text("Loading AI models..."));
    }
    if (modelsViewModel.errorMessage != null) {
      return Center(
        child: Text(
          "Error loading models: ${modelsViewModel.errorMessage}",
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (vqaModels.isEmpty) {
      return const Center(child: Text("No VQA models available from server."));
    }

    // Set the default model in the ViewModel if it's not set and models are available
    if (vqaViewModel.selectedModel == null && vqaModels.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vqaViewModel.setModel(vqaModels.first);
      });
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: vqaViewModel.selectedModel,
            decoration: const InputDecoration(
              labelText: 'AI Model',
              border: OutlineInputBorder(),
            ),
            items:
                vqaModels.map((model) {
                  return DropdownMenuItem(value: model, child: Text(model));
                }).toList(),
            // Call the ViewModel's method on change
            onChanged: (value) => vqaViewModel.setModel(value),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            // Use capitalize logic for display if mode is stored as lowercase
            value: vqaViewModel.selectedMode?.replaceFirst(
              vqaViewModel.selectedMode![0],
              vqaViewModel.selectedMode![0].toUpperCase(),
            ),
            decoration: const InputDecoration(
              labelText: 'Mode',
              border: OutlineInputBorder(),
            ),
            items:
                _analysisModes.map((mode) {
                  return DropdownMenuItem(value: mode, child: Text(mode));
                }).toList(),
            // Call the ViewModel's method on change
            onChanged: (value) => vqaViewModel.setMode(value?.toLowerCase()),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionInput() {
    return TextField(
      controller: _questionController,
      decoration: const InputDecoration(
        labelText: "Ask a question about the scene",
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isLoading = context.select((VqaViewModel vm) => vm.isLoading);
    return ElevatedButton(
      onPressed: isLoading ? null : _getAnswer,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      child: const Text("Get Answer"),
    );
  }

  Widget _buildResultDisplay(VqaViewModel vqaViewModel) {
    if (vqaViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vqaViewModel.errorMessage != null) {
      return Center(
        child: Text(
          "Error: ${vqaViewModel.errorMessage}",
          style: const TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (vqaViewModel.vqaResult != null) {
      final result = vqaViewModel.vqaResult!;
      final processingTime = result.processingTime.toStringAsFixed(2);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              "Answer: ${result.answer}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
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
