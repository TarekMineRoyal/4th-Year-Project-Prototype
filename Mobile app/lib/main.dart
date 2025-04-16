import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart'; // For TextInputFormatters

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
      home: const ImageSelectorScreen(),
    );
  }
}

class ImageSelectorScreen extends StatefulWidget {
  const ImageSelectorScreen({super.key});

  @override
  State<ImageSelectorScreen> createState() => _ImageSelectorScreenState();
}

class _ImageSelectorScreenState extends State<ImageSelectorScreen> {
  File? _selectedImage;
  String? _selectedOption;
  bool _isSending = false;
  final List<String> _options = ['yolov8n', 'yolov8m', 'yolov8x'];
  final List<String> _analysisResults = [];
  final ImagePicker _picker = ImagePicker();

  // IP Address Controller
  final TextEditingController _ipController =
      TextEditingController()..text = '192.168.138.190'; // Default IP

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (!mounted) return;
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both image and option')),
      );
      return;
    }

    // Validate IP address
    if (_ipController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter server IP address')),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _analysisResults.clear();
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://${_ipController.text}:8000/upload'),
      );

      // Add form data
      request.fields['option'] = _selectedOption!;

      // Add image file with proper type
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
        final List<dynamic> resultList = jsonDecode(responseBody);
        setState(() {
          _analysisResults.addAll(resultList.map((e) => e.toString()));
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
      appBar: AppBar(title: const Text('Image Analyzer'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IP Address Input
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                controller: _ipController,
                decoration: InputDecoration(
                  labelText: 'Server IP Address',
                  hintText: 'e.g. 192.168.1.100',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.network_wifi),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^([0-9]{1,3}\.){0,3}[0-9]{1,3}$'),
                  ),
                ],
              ),
            ),

            // Image and Results Row
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Preview
                  Expanded(
                    flex: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          _selectedImage == null
                              ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No image selected',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              )
                              : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Analysis Results
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.blueGrey.shade100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child:
                          _analysisResults.isEmpty
                              ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Analysis results will appear here',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                itemCount: _analysisResults.length,
                                itemBuilder:
                                    (context, index) => Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          _analysisResults[index],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Option Selector
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select analysis mode',
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
            // Analyze Button
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
                      : const Text('ANALYZE IMAGE'),
            ),
            const SizedBox(height: 16),
            // Camera/Gallery Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
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
            ),
          ],
        ),
      ),
    );
  }
}
