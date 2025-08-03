// lib/models/vqa_result.dart

class VqaResult {
  final String answer;
  final double processingTime;
  final String? analyzedPath;

  VqaResult({
    required this.answer,
    required this.processingTime,
    this.analyzedPath,
  });

  factory VqaResult.fromJson(Map<String, dynamic> json) {
    return VqaResult(
      answer: json['answer'],
      processingTime: (json['processing_time'] as num).toDouble(),
      analyzedPath: json['analyzed_path'],
    );
  }
}
