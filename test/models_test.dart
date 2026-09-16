import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llom/models/book_model.dart';
import 'package:llom/models/shelf_model.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/models/library_model.dart';

void main() {
  group('ShelfModel tests', () {
    final now = DateTime.now();

    test('toMap and fromMap work properly', () {
      final shelf = ShelfModel(
        id: 'shelf-123',
        code: 'E1-B2',
        photoUrl: 'https://example.com/photo.jpg',
        bookCount: 15,
        createdAt: now,
      );

      final map = shelf.toMap();
      expect(map['code'], 'E1-B2');
      expect(map['photoUrl'], 'https://example.com/photo.jpg');
      expect(map['bookCount'], 15);
      expect(map['createdAt'], isA<Timestamp>());

      final parsed = ShelfModel.fromMap(map, 'shelf-123');
      expect(parsed.id, shelf.id);
      expect(parsed.code, shelf.code);
      expect(parsed.photoUrl, shelf.photoUrl);
      expect(parsed.bookCount, shelf.bookCount);
      expect(parsed.createdAt.millisecondsSinceEpoch ~/ 1000,
          now.millisecondsSinceEpoch ~/ 1000);
    });

    test('copyWith works properly', () {
      final shelf = ShelfModel(
        id: 's1',
        code: 'E1-B1',
        createdAt: now,
      );

      final updated = shelf.copyWith(bookCount: 5, code: 'E1-B2');
      expect(updated.id, 's1');
      expect(updated.code, 'E1-B2');
      expect(updated.bookCount, 5);
      expect(updated.createdAt, now);
    });
  });

  group('BookModel tests', () {
    final now = DateTime.now();

    test('toMap and fromMap work properly', () {
      final book = BookModel(
        id: 'b1',
        title: 'La plaça del Diamant',
        author: 'Mercè Rodoreda',
        shelfCode: 'E1-B2',
        positionIndex: 3,
        photoUrl: 'https://example.com/book.jpg',
        notes: 'Primera edició',
        box: [100, 200, 800, 300],
        synopsis: 'La història de la Natàlia, Colometa.',
        coverUrl: 'https://example.com/cover.jpg',
        pageCount: 256,
        publishedYear: '1962',
        infoUrl: 'https://books.google.com/test',
        enrichmentAttempts: 2,
        createdAt: now,
      );

      final map = book.toMap();
      expect(map['title'], 'La plaça del Diamant');
      expect(map['author'], 'Mercè Rodoreda');
      expect(map['shelfCode'], 'E1-B2');
      expect(map['positionIndex'], 3);
      expect(map['photoUrl'], 'https://example.com/book.jpg');
      expect(map['notes'], 'Primera edició');
      expect(map['box'], [100, 200, 800, 300]);
      expect(map['synopsis'], 'La història de la Natàlia, Colometa.');
      expect(map['coverUrl'], 'https://example.com/cover.jpg');
      expect(map['pageCount'], 256);
      expect(map['publishedYear'], '1962');
      expect(map['infoUrl'], 'https://books.google.com/test');
      expect(map['enrichmentAttempts'], 2);
      expect(map['createdAt'], isA<Timestamp>());

      final parsed = BookModel.fromMap(map, 'b1');
      expect(parsed.id, book.id);
      expect(parsed.title, book.title);
      expect(parsed.author, book.author);
      expect(parsed.shelfCode, book.shelfCode);
      expect(parsed.positionIndex, book.positionIndex);
      expect(parsed.photoUrl, book.photoUrl);
      expect(parsed.notes, book.notes);
      expect(parsed.box, [100, 200, 800, 300]);
      expect(parsed.synopsis, book.synopsis);
      expect(parsed.coverUrl, book.coverUrl);
      expect(parsed.pageCount, 256);
      expect(parsed.publishedYear, '1962');
      expect(parsed.infoUrl, book.infoUrl);
      expect(parsed.enrichmentAttempts, 2);
    });

    test('copyWith works properly', () {
      final book = BookModel(
        id: 'b1',
        title: 'Títol',
        author: 'Autor',
        shelfCode: 'E1-B1',
        positionIndex: 0,
        createdAt: now,
      );

      final updated = book.copyWith(
        title: 'Nou Títol',
        positionIndex: 2,
        synopsis: 'Nova sinopsi',
        coverUrl: 'https://example.com/new.jpg',
      );

      expect(updated.id, 'b1');
      expect(updated.title, 'Nou Títol');
      expect(updated.author, 'Autor');
      expect(updated.positionIndex, 2);
      expect(updated.synopsis, 'Nova sinopsi');
      expect(updated.coverUrl, 'https://example.com/new.jpg');
    });
  });

  group('UserModel tests', () {
    final now = DateTime.now();

    test('toMap and fromMap work properly', () {
      final user = UserModel(
        uid: 'user_123',
        email: 'test@llom.cat',
        displayName: 'Jeroni',
        photoUrl: 'https://example.com/avatar.jpg',
        activeLibraryId: 'lib_abc',
        createdAt: now,
      );

      final map = user.toMap();
      expect(map['uid'], 'user_123');
      expect(map['email'], 'test@llom.cat');
      expect(map['displayName'], 'Jeroni');
      expect(map['photoUrl'], 'https://example.com/avatar.jpg');
      expect(map['activeLibraryId'], 'lib_abc');
      expect(map['createdAt'], isA<Timestamp>());

      final parsed = UserModel.fromMap(map, 'user_123');
      expect(parsed.uid, user.uid);
      expect(parsed.email, user.email);
      expect(parsed.displayName, user.displayName);
      expect(parsed.photoUrl, user.photoUrl);
      expect(parsed.activeLibraryId, user.activeLibraryId);
      expect(
        parsed.createdAt.millisecondsSinceEpoch ~/ 1000,
        now.millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('copyWith works properly', () {
      final user = UserModel(
        uid: 'u1',
        email: 'original@llom.cat',
        photoUrl: 'https://example.com/old.jpg',
        createdAt: now,
      );

      final updated = user.copyWith(
        displayName: 'Nou Nom',
        photoUrl: 'https://example.com/new.jpg',
        activeLibraryId: 'lib_xyz',
      );

      expect(updated.uid, 'u1');
      expect(updated.email, 'original@llom.cat');
      expect(updated.displayName, 'Nou Nom');
      expect(updated.photoUrl, 'https://example.com/new.jpg');
      expect(updated.activeLibraryId, 'lib_xyz');
      expect(updated.createdAt, now);
    });
  });

  group('LibraryModel tests', () {
    final now = DateTime.now();

    test('toMap and fromMap work properly', () {
      final library = LibraryModel(
        id: 'lib_001',
        name: 'Biblioteca Cal Jeroni',
        ownerId: 'user_owner',
        inviteCode: 'LLOM84',
        members: {
          'user_owner': 'owner',
          'user_editor': 'editor',
          'user_viewer': 'viewer',
        },
        memberUids: ['user_owner', 'user_editor', 'user_viewer'],
        createdAt: now,
      );

      final map = library.toMap();
      expect(map['id'], 'lib_001');
      expect(map['name'], 'Biblioteca Cal Jeroni');
      expect(map['ownerId'], 'user_owner');
      expect(map['inviteCode'], 'LLOM84');
      expect(map['members'], isA<Map<String, String>>());
      expect(map['memberUids'], isA<List<String>>());
      expect(map['createdAt'], isA<Timestamp>());

      final parsed = LibraryModel.fromMap(map, 'lib_001');
      expect(parsed.id, library.id);
      expect(parsed.name, library.name);
      expect(parsed.ownerId, library.ownerId);
      expect(parsed.inviteCode, library.inviteCode);
      expect(parsed.members.length, 3);
      expect(parsed.members['user_editor'], 'editor');
      expect(parsed.memberUids.length, 3);
      expect(parsed.memberUids, contains('user_owner'));
    });

    test('fromMap fallback creates memberUids from members and ownerId when missing', () {
      final mapWithoutUids = {
        'id': 'lib_legacy',
        'name': 'Biblioteca Antiga',
        'ownerId': 'legacy_owner',
        'inviteCode': 'LEG123',
        'members': {'member_1': 'viewer'},
        'createdAt': Timestamp.fromDate(now),
      };

      final parsed = LibraryModel.fromMap(mapWithoutUids, 'lib_legacy');
      expect(parsed.memberUids, contains('member_1'));
      expect(parsed.memberUids, contains('legacy_owner'));
    });

    test('copyWith works properly', () {
      final library = LibraryModel(
        id: 'lib_cp',
        name: 'Biblioteca Original',
        ownerId: 'owner_1',
        inviteCode: 'OLD123',
        members: {'owner_1': 'owner'},
        memberUids: ['owner_1'],
        createdAt: now,
      );

      final updated = library.copyWith(
        name: 'Biblioteca Modificada',
        inviteCode: 'NEW456',
        members: {'owner_1': 'owner', 'member_2': 'editor'},
        memberUids: ['owner_1', 'member_2'],
      );

      expect(updated.name, 'Biblioteca Modificada');
      expect(updated.inviteCode, 'NEW456');
      expect(updated.members['member_2'], 'editor');
      expect(updated.memberUids.length, 2);
    });

    test('getUserRole returns correct role for members', () {
      final library = LibraryModel(
        id: 'lib_001',
        name: 'Biblioteca Cal Jeroni',
        ownerId: 'user_owner',
        inviteCode: 'LLOM84',
        members: {
          'user_owner': 'owner',
          'user_editor': 'editor',
          'user_viewer': 'viewer',
        },
        memberUids: ['user_owner', 'user_editor', 'user_viewer'],
        createdAt: now,
      );

      expect(library.getUserRole('user_owner'), Role.owner);
      expect(library.getUserRole('user_editor'), Role.editor);
      expect(library.getUserRole('user_viewer'), Role.viewer);
      expect(library.getUserRole('stranger_user'), Role.none);
    });

    test('getUserRole falls back to owner if uid equals ownerId without map entry', () {
      final library = LibraryModel(
        id: 'lib_002',
        name: 'Biblioteca Nova',
        ownerId: 'owner_alone',
        inviteCode: 'TEST12',
        members: {},
        memberUids: ['owner_alone'],
        createdAt: now,
      );

      expect(library.getUserRole('owner_alone'), Role.owner);
      expect(library.getUserRole('stranger'), Role.none);
    });

    test('Role enum serialization and deserialization', () {
      expect(Role.fromString('owner'), Role.owner);
      expect(Role.fromString('EDITOR'), Role.editor);
      expect(Role.fromString('viewer'), Role.viewer);
      expect(Role.fromString('other'), Role.none);
      expect(Role.fromString(null), Role.none);

      expect(Role.owner.toRoleString(), 'owner');
      expect(Role.editor.toRoleString(), 'editor');
      expect(Role.viewer.toRoleString(), 'viewer');
      expect(Role.none.toRoleString(), 'none');
    });
  });
}

