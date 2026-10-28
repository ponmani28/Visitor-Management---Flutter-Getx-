import 'package:flutter_test/flutter_test.dart';
import 'package:visitor_management/app/data/controllers/auth_controller.dart';

void main() {
  group('AuthController demo sign-in', () {
    late AuthController controller;

    setUp(() {
      controller = AuthController();
    });

    test('accepts any non-empty username and password', () {
      expect(
        controller.signIn(username: 'any-user', password: 'any-password'),
        isTrue,
      );
      expect(controller.isAuthenticated, isTrue);
    });

    test('rejects a missing username or password', () {
      expect(controller.signIn(username: ' ', password: 'password'), isFalse);
      expect(controller.signIn(username: 'user', password: ''), isFalse);
      expect(controller.isAuthenticated, isFalse);
    });

    test('sign-out clears the in-memory session', () {
      controller.signIn(username: 'user', password: 'password');

      controller.signOut();

      expect(controller.isAuthenticated, isFalse);
    });
  });
}
