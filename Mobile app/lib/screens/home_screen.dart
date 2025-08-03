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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SettingsService _settingsService = SettingsService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // This ensures we don't try to show a dialog while the first frame is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptForIp();
    });
  }

  void _checkAndPromptForIp() async {
    final ip = _settingsService.getIpAddress();
    if (ip == null || ip.isEmpty) {
      // The dialog itself is async, so we await it.
      await _showIpDialog();
    } else {
      // If IP already exists, try to initialize user right away.
      try {
        await _apiService.initializeUser();
        // Add the mounted check here as well for safety.
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
    // It's good practice to store the BuildContext of the dialog's parent.
    final currentContext = context;

    await showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text("Backend Configuration"),
            content: TextField(
              controller: ipController,
              decoration: const InputDecoration(
                hintText: "Enter your laptop's IP",
              ),
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (ipController.text.isNotEmpty) {
                    // 1. Save the IP address
                    _settingsService.setIpAddress(ipController.text);

                    // Close the dialog
                    Navigator.of(dialogContext).pop();

                    // 2. Try to initialize the user ID now that we have an IP
                    try {
                      await _apiService.initializeUser();
                    } catch (e) {
                      print("Failed to initialize user after setting IP: $e");
                      // Check if mounted before showing SnackBar
                      if (mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(
                            content: Text("Could not get User ID from server."),
                          ),
                        );
                      }
                    }

                    // --- THE FIX ---
                    // 3. Before using the context, check if the widget is still mounted.
                    if (!mounted) return;

                    // Now it's safe to use the context to refresh the ViewModel.
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Vision AI Toolbox',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 20,
              ),
            ),
            if (homeViewModel.userId != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'ID: ${homeViewModel.userId}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // We can add a settings icon to allow changing the IP later
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showIpDialog,
            tooltip: 'Change Backend IP',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureCard(
                context,
                Icons.remove_red_eye_outlined,
                'Interactive Scene Explorer',
                'Ask questions about your surroundings',
                const VQAScreen(),
                Colors.blue,
              ),
              const SizedBox(height: 30),
              _buildFeatureCard(
                context,
                Icons.text_fields_rounded,
                'Text Reader',
                'Read text from signs and documents',
                const OCRScreen(),
                Colors.green,
              ),
              const SizedBox(height: 30),
              _buildFeatureCard(
                context,
                Icons.memory, // Or any icon you like
                'Live Session Q&A',
                'Record a scene and ask questions about it',
                const SessionScreen(), // Navigate to your new screen
                Colors.orange, // Or any color you like
              ),
            ],
          ),
        ),
      ),
    );
  }

  // This buildFeatureCard method remains unchanged.
  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Widget screen,
    Color color,
  ) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          ),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withOpacity(0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
