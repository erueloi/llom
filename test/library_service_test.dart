import 'package:flutter_test/flutter_test.dart';
import 'package:llom/services/library_service.dart';

void main() {
  group('LibraryException tests', () {
    test('LibraryException stores message and code and formats toString', () {
      const exception = LibraryException('Codi invàlid', code: 'not-found');
      expect(exception.message, 'Codi invàlid');
      expect(exception.code, 'not-found');
      expect(exception.toString(), 'Codi invàlid');
    });
  });

  group('LibraryService input validation and code generation', () {
    test('createLibrary rejects empty name or ownerUid', () async {
      final service = LibraryService();

      expect(
        () => service.createLibrary(name: '', ownerUid: 'uid123'),
        throwsA(isA<LibraryException>().having(
          (e) => e.message,
          'message',
          contains('buit'),
        )),
      );

      expect(
        () => service.createLibrary(name: 'Biblioteca', ownerUid: ''),
        throwsA(isA<LibraryException>().having(
          (e) => e.message,
          'message',
          contains('no és vàlid'),
        )),
      );
    });

    test('joinLibraryByCode rejects empty code or uid', () async {
      final service = LibraryService();

      expect(
        () => service.joinLibraryByCode(inviteCode: '   ', uid: 'uid123'),
        throwsA(isA<LibraryException>().having(
          (e) => e.message,
          'message',
          contains('buit'),
        )),
      );

      expect(
        () => service.joinLibraryByCode(inviteCode: 'LLOM84', uid: '   '),
        throwsA(isA<LibraryException>().having(
          (e) => e.message,
          'message',
          contains('no és vàlid'),
        )),
      );
    });

    test('Code generator produces 6-character uppercase alphanumeric code', () {
      final service = LibraryService();
      final code = service.generateInviteCode();
      expect(code.length, 6);
      expect(RegExp(r'^[A-Z0-9]{6}$').hasMatch(code), isTrue);

      final customService = LibraryService(codeGenerator: () => 'ABC123');
      expect(customService.generateInviteCode(), 'ABC123');
    });
  });
}
