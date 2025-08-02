// lib/viewmodels/home_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../services/user_service.dart';

class HomeViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  String? _userId;

  String? get userId => _userId;

  HomeViewModel() {
    loadUserId();
  }

  Future<void> loadUserId() async {
    _userId = await _userService.getUserId();
    notifyListeners();
  }
}
