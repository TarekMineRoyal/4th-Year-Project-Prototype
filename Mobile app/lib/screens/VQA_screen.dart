// lib/screens/vqa_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../viewmodels/vqa_viewmodel.dart';

class VQAScreen extends StatefulWidget {
  const VQAScreen({super.key});

  @override
  _VQAScreenState createState() => _VQAScreenState();
}

class _VQAScreenState extends State<VQAScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _image;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
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
              const SizedBox(height: 24),

              // --- ADDED ---
              // Dropdown for selecting the AI model.
              // This is the UI counterpart to the logic we added in the ViewModel.
              DropdownButtonFormField<String>(
                value: vqaViewModel.selectedModel,
                items: const [
                  DropdownMenuItem(
                    value: 'gemini-1.5-flash-latest',
                    child: Text('Gemini (Online)'),
                  ),
                  DropdownMenuItem(
                    value: 'llava',
                    child: Text('Llava (Offline)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    // Use context.read to call the state update method
                    // without causing a rebuild here.
                    context.read<VqaViewModel>().setModel(value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Select AI Model',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // --- END ADDED SECTION ---
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: "Ask a question about the scene",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: vqaViewModel.isLoading ? null : _getAnswer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Get Answer"),
              ),
              const SizedBox(height: 30),
              if (vqaViewModel.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (vqaViewModel.errorMessage != null)
                Center(
                  child: Text(
                    "Error: ${vqaViewModel.errorMessage}",
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (vqaViewModel.vqaResult != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Answer: ${vqaViewModel.vqaResult!.answer}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
