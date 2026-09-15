import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bookcase_model.dart';

/// Servei per gestionar les estanteries / mobles sota Cloud Firestore a `libraries/{libraryId}/bookcases`
class BookcaseService {
  final FirebaseFirestore? _firestoreInstance;

  BookcaseService({FirebaseFirestore? firestore})
      : _firestoreInstance = firestore;

  FirebaseFirestore? get _firestore {
    try {
      return _firestoreInstance ?? FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? _bookcasesRef(String libraryId) {
    return _firestore?.collection('libraries').doc(libraryId).collection('bookcases');
  }

  /// Retorna un Stream de les estanteries d'una biblioteca en temps real
  Stream<List<BookcaseModel>> getBookcases(String libraryId) {
    if (libraryId.trim().isEmpty) {
      return Stream.value([]);
    }

    final ref = _bookcasesRef(libraryId);
    if (ref == null) {
      return Stream.value([]);
    }

    return ref.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BookcaseModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  /// Afegeix un nou moble d'estanteria a la biblioteca a Firestore
  Future<BookcaseModel> addBookcase(String libraryId, BookcaseModel bookcase) async {
    final cleanLibId = libraryId.trim();
    if (cleanLibId.isEmpty) {
      throw ArgumentError('libraryId no pot estar buit');
    }

    final collection = _bookcasesRef(cleanLibId);
    if (collection == null) {
      throw StateError('FirebaseFirestore no està disponible');
    }

    final docRef = bookcase.id.trim().isNotEmpty
        ? collection.doc(bookcase.id.trim())
        : collection.doc();

    final toSave = bookcase.id.isEmpty
        ? bookcase.copyWith(id: docRef.id)
        : bookcase;

    await docRef.set(toSave.toMap());
    return toSave;
  }

  /// Elimina una estanteria d'una biblioteca
  Future<void> deleteBookcase(String libraryId, String bookcaseId) async {
    final cleanLibId = libraryId.trim();
    final cleanBookcaseId = bookcaseId.trim();

    if (cleanLibId.isEmpty || cleanBookcaseId.isEmpty) {
      throw ArgumentError('libraryId i bookcaseId són obligatoris');
    }

    final collection = _bookcasesRef(cleanLibId);
    if (collection == null) {
      throw StateError('FirebaseFirestore no està disponible');
    }

    await collection.doc(cleanBookcaseId).delete();
  }
}
