// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../viewmodels/home_viewmodel.dart';
import 'ocr_screen.dart';
import 'vqa_screen.dart';
import 'session_screen.dart';
import '../services/api_service.dart';
import '../viewmodels/models_viewmodel.dart';

// Helper class to organize feature data, making the list easier to manage.
class _Feature {
  final String title;
  final String description;
  final IconData icon;
  final Widget screen;
  final Color color;

  _Feature({
    required this.title,
    required this.description,
    required this.icon,
    required this.screen,
    required this.color,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SettingsService _settingsService = SettingsService();
  final ApiService _apiService = ApiService();

  // A list of features, making it easy to add or remove features in the future.
  final List<_Feature> _features = [
    _Feature(
      title: 'Interactive Scene Explorer',
      description: 'Ask questions about your surroundings',
      icon: Icons.remove_red_eye_outlined,
      screen: const VQAScreen(),
      color: Colors.blue,
    ),
    _Feature(
      title: 'Text Reader',
      description: 'Read text from signs and documents',
      icon: Icons.text_fields_rounded,
      screen: const OCRScreen(),
      color: Colors.green,
    ),
    _Feature(
      title: 'Live Session Q&A',
      description: 'Record a scene and ask questions about it',
      icon: Icons.memory,
      screen: const SessionScreen(),
      color: Colors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptForIp();
    });
  }

  void _checkAndPromptForIp() async {
    final ip = _settingsService.getIpAddress();
    if (ip == null || ip.isEmpty) {
      await _showIpDialog();
    } else {
      try {
        await _apiService.initializeUser();
        if (!mounted) return;
        context.read<HomeViewModel>().loadUserId();
        context.read<ModelsViewModel>().fetchModels();
      } catch (e) {
        print("Failed to initialize user on startup: $e");
      }
    }
  }

  Future<void> _showIpDialog() async {
    final ipController = TextEditingController();
    final currentContext = context;

    await showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            title: Semantics(
              header: true,
              child: const Text("Backend Configuration"),
            ),
            content: TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: "Server IP Address",
                hintText: "Enter your laptop's IP",
              ),
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (ipController.text.isNotEmpty) {
                    _settingsService.setIpAddress(ipController.text);
                    Navigator.of(dialogContext).pop();
                    try {
                      await _apiService.initializeUser();
                    } catch (e) {
                      print("Failed to initialize user after setting IP: $e");
                      if (mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(
                            content: Text("Could not get User ID from server."),
                          ),
                        );
                      }
                    }
                    if (!mounted) return;
                    currentContext.read<HomeViewModel>().loadUserId();
                    currentContext.read<ModelsViewModel>().fetchModels();
                  }
                },
                child: const Text("Save for this session"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Column(
            children: [
              const Text('AuraLens Vision Box'), // <-- TITLE UPDATED HERE
              if (homeViewModel.userId != null)
                Text(
                  'ID: ${homeViewModel.userId}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          Tooltip(
            message: 'Change Backend IP',
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showIpDialog,
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        itemCount: _features.length,
        itemBuilder: (context, index) {
          final feature = _features[index];
          return _buildFeatureButton(context, feature);
        },
      ),
    );
  }

  /// Builds a large, accessible button for a feature.
  Widget _buildFeatureButton(BuildContext context, _Feature feature) {
    return Semantics(
      label: "${feature.title}. ${feature.description}",
      button: true,
      excludeSemantics: true,
      child: Padding(
        // The bottom padding here controls the spacing between buttons.
        padding: const EdgeInsets.only(
          bottom: 24.0,
        ), // <-- SPACING INCREASED HERE
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => feature.screen),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: feature.color.withAlpha(40),
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
          child: Row(
            children: [
              Icon(feature.icon, size: 36, color: feature.color),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}
