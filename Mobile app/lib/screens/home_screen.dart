// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'ocr_screen.dart';
import 'vqa_screen.dart';
import 'video_analysis_screen.dart';
import 'session_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    // This ensures we don't try to show a dialog while the first frame is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptForIp();
    });
  }

  void _checkAndPromptForIp() {
    final ip = _settingsService.getIpAddress();
    if (ip == null || ip.isEmpty) {
      _showIpDialog();
    }
  }

  void _showIpDialog() {
    final ipController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false, // User MUST enter an IP
      builder:
          (context) => AlertDialog(
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
                onPressed: () {
                  if (ipController.text.isNotEmpty) {
                    _settingsService.setIpAddress(ipController.text);
                    Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vision AI Toolbox',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 22,
          ),
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
                Icons.videocam_rounded,
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
                Icons.videocam_rounded,
                'Live Scene Analysis',
                'Analyze your surroundings in real-time',
                const VideoAnalysisScreen(),
                Colors.purple,
              ),
              _buildFeatureCard(
                context,
                Icons.memory, // Or any icon you like
                'Live Session Q&A',
                'Record a scene and ask questions about it',
                const SessionScreen(), // Navigate to your new screen
                Colors.orange, // Or any color you like
              ),
              const SizedBox(height: 30),
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
        height: 180,
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
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
