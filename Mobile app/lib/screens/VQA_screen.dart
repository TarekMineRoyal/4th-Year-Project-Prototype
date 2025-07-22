// lib/screens/vqa_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../viewmodels/vqa_viewmodel.dart';

class VQAScreen extends StatefulWidget {
  const VQAScreen({super.key});

  @override
  State<VQAScreen> createState() => _VQAScreenState();
}

class _VQAScreenState extends State<VQAScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _image;

  // This is UI-level logic to handle picking an image and updating the local state.
  // It's appropriate to keep it here in the State class.
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

  // This method delegates the business logic to the ViewModel.
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
              // Use private builder methods to keep the build method clean.
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildQuestionInput(),
              const SizedBox(height: 16),
              _buildSubmitButton(),
              const SizedBox(height: 30),
              _buildResultDisplay(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for displaying the image and the button to take a picture.
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

  // Widget for the question text field.
  Widget _buildQuestionInput() {
    return TextField(
      controller: _questionController,
      decoration: const InputDecoration(
        labelText: "Ask a question about the scene",
        border: OutlineInputBorder(),
      ),
    );
  }

  // Widget for the submit button.
  Widget _buildSubmitButton() {
    // Listen to only the isLoading state for this button.
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

  // Widget to display the result, loading indicator, or an error message.
  Widget _buildResultDisplay() {
    final vqaViewModel = context.watch<VqaViewModel>();

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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "Answer: ${vqaViewModel.vqaResult!.answer}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Return an empty container if there's no result, error, or loading state.
    return const SizedBox.shrink();
  }
}
