import 'package:flutter/material.dart';
import 'ocr_screen.dart';
import 'vqa_screen.dart';
import 'video_analysis_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
              // Card for the Interactive Scene Explorer (VQA)
              _buildFeatureCard(
                context,
                Icons.question_answer_rounded,
                'Interactive Scene Explorer',
                'Ask questions about your surroundings',
                const VQAScreen(),
                Colors.blue,
              ),
              const SizedBox(height: 30),
              // Card for the Text Reader (OCR)
              _buildFeatureCard(
                context,
                Icons.text_fields_rounded,
                'Text Reader',
                'Read text from signs and documents',
                const OCRScreen(),
                Colors.green,
              ),
              const SizedBox(height: 30),
              // Card for the Video analysis
              _buildFeatureCard(
                context,
                Icons.videocam_rounded, // New Icon
                'Live Scene Analysis', // New Title
                'Analyze your surroundings in real-time', // New Subtitle
                const VideoAnalysisScreen(), // Navigate to the new screen
                Colors.purple, // New Color
              ),
            ],
          ),
        ),
      ),
    );
  }

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
