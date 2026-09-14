import 'package:flutter_test/flutter_test.dart';
import 'package:llom/services/auth_service.dart';

void main() {
  group('AuthException tests', () {
    test('AuthException stores message and code and formats toString', () {
      const exception = AuthException('Correu invàlid', code: 'invalid-email');
      expect(exception.message, 'Correu invàlid');
      expect(exception.code, 'invalid-email');
      expect(exception.toString(), 'Correu invàlid');
    });

    test('AuthException without code works properly', () {
      const exception = AuthException('Error general');
      expect(exception.message, 'Error general');
      expect(exception.code, isNull);
      expect(exception.toString(), 'Error general');
    });
  });
}
