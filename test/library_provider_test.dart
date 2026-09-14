import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:llom/models/library_model.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/providers/library_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryProvider tests', () {
    final now = DateTime.now();

    final userOwner = UserModel(
      uid: 'user_owner',
      email: 'owner@llom.cat',
      displayName: 'Propietari',
      createdAt: now,
    );

    final userEditor = UserModel(
      uid: 'user_editor',
      email: 'editor@llom.cat',
      displayName: 'Editor',
      createdAt: now,
    );

    final userViewer = UserModel(
      uid: 'user_viewer',
      email: 'viewer@llom.cat',
      displayName: 'Lector',
      createdAt: now,
    );

    final libraryA = LibraryModel(
      id: 'lib_a',
      name: 'Biblioteca Principal',
      ownerId: 'user_owner',
      inviteCode: 'LLOM01',
      members: {
        'user_owner': 'owner',
        'user_editor': 'editor',
        'user_viewer': 'viewer',
      },
      memberUids: ['user_owner', 'user_editor', 'user_viewer'],
      createdAt: now,
    );

    final libraryB = LibraryModel(
      id: 'lib_b',
      name: 'Biblioteca Secundària',
      ownerId: 'user_editor',
      inviteCode: 'LLOM02',
      members: {
        'user_editor': 'owner',
        'user_viewer': 'viewer',
      },
      memberUids: ['user_editor', 'user_viewer'],
      createdAt: now,
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial state is correct', () {
      final provider = LibraryProvider();
      expect(provider.currentUser, isNull);
      expect(provider.activeLibrary, isNull);
      expect(provider.userLibraries, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.hasActiveLibrary, isFalse);
      expect(provider.currentRole, 'viewer');
      expect(provider.isOwner, isFalse);
      expect(provider.canEdit, isFalse);
      expect(provider.isViewerOnly, isTrue);
    });

    test('Role getters reflect owner, editor and viewer correctly', () {
      final provider = LibraryProvider();
      provider.activeLibrary = libraryA;

      // Com a Owner
      provider.currentUser = userOwner;
      expect(provider.currentRole, 'owner');
      expect(provider.isOwner, isTrue);
      expect(provider.canEdit, isTrue);
      expect(provider.isViewerOnly, isFalse);

      // Com a Editor
      provider.currentUser = userEditor;
      expect(provider.currentRole, 'editor');
      expect(provider.isOwner, isFalse);
      expect(provider.canEdit, isTrue);
      expect(provider.isViewerOnly, isFalse);

      // Com a Viewer
      provider.currentUser = userViewer;
      expect(provider.currentRole, 'viewer');
      expect(provider.isOwner, isFalse);
      expect(provider.canEdit, isFalse);
      expect(provider.isViewerOnly, isTrue);
    });

    test('switchLibrary updates activeLibrary and saves to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = LibraryProvider(prefs: prefs);

      expect(provider.hasActiveLibrary, isFalse);

      await provider.switchLibrary(libraryA);
      expect(provider.activeLibrary, libraryA);
      expect(provider.hasActiveLibrary, isTrue);
      expect(prefs.getString(LibraryProvider.activeLibraryKey), 'lib_a');

      await provider.switchLibrary(libraryB);
      expect(provider.activeLibrary, libraryB);
      expect(prefs.getString(LibraryProvider.activeLibraryKey), 'lib_b');
    });
  });
}
