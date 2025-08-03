// lib/models/session_question_result.dart

class SessionQuestionResult {
  final String sessionId;
  final String? answer;

  SessionQuestionResult({required this.sessionId, this.answer});

  factory SessionQuestionResult.fromJson(Map<String, dynamic> json) {
    return SessionQuestionResult(
      sessionId: json['session_id'],
      answer: json['answer'],
    );
  }
}
