class VideoProcessingResult {
  final String status;
  final String sessionId;

  VideoProcessingResult({required this.status, required this.sessionId});

  factory VideoProcessingResult.fromJson(Map<String, dynamic> json) {
    return VideoProcessingResult(
      status: json['status'],
      sessionId: json['session_id'],
    );
  }
}
