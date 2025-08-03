// lib/models/user_init_response.dart

class UserInitResponse {
  final String userId;

  UserInitResponse({required this.userId});

  factory UserInitResponse.fromJson(Map<String, dynamic> json) {
    return UserInitResponse(userId: json['user_id']);
  }
}
