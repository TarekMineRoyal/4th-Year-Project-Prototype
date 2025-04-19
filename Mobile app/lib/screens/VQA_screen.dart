import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VQA Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const VQAScreen(),
    );
  }
}

class VQAScreen extends StatefulWidget {
  const VQAScreen({super.key});

  @override
  State<VQAScreen> createState() => _VQAScreenState();
}

class _VQAScreenState extends State<VQAScreen> {
  File? _selectedImage;
  String? _selectedOption;
  bool _isSending = false;
  final List<String> _options = ['blip-vqa-base', 'vqa_model_2'];
  String? _answer;
  double? _processingTime;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _ipController =
      TextEditingController()..text = '192.168.138.190';
  final TextEditingController _questionController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (!mounted) return;
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _answer = null;
          _processingTime = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Camera error: ${e.toString()}')));
    }
  }

  Future<void> _sendForAnalysis() async {
    if (_selectedImage == null || _selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select image and model')),
      );
      return;
    }
    if (_ipController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter server IP address')),
      );
      return;
    }
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your question')),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _answer = null;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://${_ipController.text}:8000/vqa'),
      );
      request.fields['option'] = _selectedOption!;
      request.fields['question'] = _questionController.text;

      final fileExt = _selectedImage!.path.split('.').last.toLowerCase();
      final contentType =
          fileExt == 'png'
              ? MediaType('image', 'png')
              : MediaType('image', 'jpeg');
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
          contentType: contentType,
        ),
      );

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (!mounted) return;
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        setState(() {
          _answer = jsonResponse['answer'];
          _processingTime = jsonResponse['processing_time'].toDouble();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed (${response.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Question Answering'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _ipController,
                decoration: InputDecoration(
                  labelText: 'Server IP Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.network_wifi),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    _selectedImage == null
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image_outlined,
                              size: 60,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No image selected',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        )
                        : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Your question',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Container(
                height: 62,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child:
                    _answer == null
                        ? Column(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Answer will appear here',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Answer:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _answer!,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Processed in ${_processingTime?.toStringAsFixed(2)}s',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select VQA model',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: _selectedOption,
                items:
                    _options
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _selectedOption = value),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSending ? null : _sendForAnalysis,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSending
                        ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                        : const Text('GET ANSWER'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    onPressed: () => _pickImage(ImageSource.camera),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
