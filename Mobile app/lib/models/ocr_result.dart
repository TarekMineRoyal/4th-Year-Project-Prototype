// lib/models/ocr_result.dart

class OcrResult {
  final String text;
  final double processingTime;
  final String? analyzedPath;

  OcrResult({
    required this.text,
    required this.processingTime,
    this.analyzedPath,
  });

  factory OcrResult.fromJson(Map<String, dynamic> json) {
    return OcrResult(
      text: json['text'],
      processingTime: (json['processing_time'] as num).toDouble(),
      analyzedPath: json['analyzed_path'],
    );
  }
}
