import 'package:get/get.dart';

class AuthController extends GetxController {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  bool signIn({required String username, required String password}) {
    if (username.trim().isEmpty || password.isEmpty) return false;
    _isAuthenticated = true;
    return true;
  }

  void signOut() {
    _isAuthenticated = false;
  }
}
