import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../models/bookcase_model.dart';

/// Servei per gestionar les estanteries / mobles i llibres sota Cloud Firestore
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

  CollectionReference<Map<String, dynamic>>? _booksRef(String libraryId) {
    return _firestore?.collection('libraries').doc(libraryId).collection('books');
  }

  /// Retorna un Stream de les estanteries d'una biblioteca ordenades per `order` i `createdAt`
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
      list.sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        return a.createdAt.compareTo(b.createdAt);
      });
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

  /// Actualitza el nom d'un moble d'estanteria
  Future<void> updateBookcaseName(String libraryId, String bookcaseId, String newName) async {
    final cleanLibId = libraryId.trim();
    final cleanBookcaseId = bookcaseId.trim();
    final cleanName = newName.trim();

    if (cleanLibId.isEmpty || cleanBookcaseId.isEmpty) {
      throw ArgumentError('libraryId i bookcaseId són obligatoris');
    }
    if (cleanName.isEmpty) {
      throw ArgumentError('El nom no pot estar buit');
    }

    final collection = _bookcasesRef(cleanLibId);
    if (collection == null) {
      throw StateError('FirebaseFirestore no està disponible');
    }

    await collection.doc(cleanBookcaseId).update({'name': cleanName});
  }

  /// Elimina una estanteria d'una biblioteca i esborra en cascada els llibres associats
  Future<void> deleteBookcase(String libraryId, String bookcaseId) async {
    final cleanLibId = libraryId.trim();
    final cleanBookcaseId = bookcaseId.trim();

    if (cleanLibId.isEmpty || cleanBookcaseId.isEmpty) {
      throw ArgumentError('libraryId i bookcaseId són obligatoris');
    }

    final collection = _bookcasesRef(cleanLibId);
    final booksColl = _booksRef(cleanLibId);
    if (collection == null || _firestore == null) {
      throw StateError('FirebaseFirestore no està disponible');
    }

    // Esborrat en cascada de llibres d'aquest moble
    if (booksColl != null) {
      try {
        final querySnapshot = await booksColl.where('bookcaseId', isEqualTo: cleanBookcaseId).get();
        if (querySnapshot.docs.isNotEmpty) {
          final batch = _firestore!.batch();
          for (final doc in querySnapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      } catch (e) {
        // Si no hi ha índex o falla la consulta per bookcaseId, intentem continuar
      }
    }

    await collection.doc(cleanBookcaseId).delete();
  }

  /// Retorna el Stream de llibres d'un moble determinat
  Stream<List<BookModel>> getBooksForBookcase(String libraryId, String bookcaseId) {
    final cleanLibId = libraryId.trim();
    final cleanBookcaseId = bookcaseId.trim();

    if (cleanLibId.isEmpty || cleanBookcaseId.isEmpty) {
      return Stream.value([]);
    }

    final booksColl = _booksRef(cleanLibId);
    if (booksColl == null) {
      return Stream.value([]);
    }

    return booksColl
        .where('bookcaseId', isEqualTo: cleanBookcaseId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BookModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.positionIndex.compareTo(b.positionIndex));
      return list;
    });
  }

  /// Afegeix un nou llibre a la col·lecció de llibres de la biblioteca i incrementa el comptador del moble
  Future<BookModel> addBook(String libraryId, BookModel book) async {
    final cleanLibId = libraryId.trim();
    if (cleanLibId.isEmpty) {
      throw ArgumentError('libraryId no pot estar buit');
    }

    final booksColl = _booksRef(cleanLibId);
    if (booksColl == null || _firestore == null) {
      throw StateError('FirebaseFirestore no està disponible');
    }

    final docRef = book.id.trim().isNotEmpty
        ? booksColl.doc(book.id.trim())
        : booksColl.doc();

    final toSave = book.id.isEmpty
        ? book.copyWith(id: docRef.id)
        : book;

    final batch = _firestore!.batch();
    batch.set(docRef, toSave.toMap());

    if (toSave.bookcaseId != null && toSave.bookcaseId!.isNotEmpty) {
      final bookcaseDoc = _bookcasesRef(cleanLibId)?.doc(toSave.bookcaseId);
      if (bookcaseDoc != null) {
        batch.set(
          bookcaseDoc,
          {'bookCount': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
    return toSave;
  }

  /// Elimina un llibre i decrementa el comptador del moble
  Future<void> deleteBook(String libraryId, String bookId, String bookcaseId) async {
    final cleanLibId = libraryId.trim();
    final cleanBookId = bookId.trim();
    final cleanBookcaseId = bookcaseId.trim();

    if (cleanLibId.isEmpty || cleanBookId.isEmpty) {
      throw ArgumentError('libraryId i bookId són obligatoris');
    }

    final booksColl = _booksRef(cleanLibId);
    if (booksColl == null || _firestore == null) {
      throw StateError('FirebaseFirestore no està disponible');
    }

    final batch = _firestore!.batch();
    batch.delete(booksColl.doc(cleanBookId));

    if (cleanBookcaseId.isNotEmpty) {
      final bookcaseDoc = _bookcasesRef(cleanLibId)?.doc(cleanBookcaseId);
      if (bookcaseDoc != null) {
        batch.set(
          bookcaseDoc,
          {'bookCount': FieldValue.increment(-1)},
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
  }

  /// Actualitza les dades d'un llibre existent i ajusta els comptadors si canvia d'estanteria
  Future<BookModel> updateBook(String libraryId, BookModel book, {String? oldBookcaseId}) async {
    final cleanLibId = libraryId.trim();
    final cleanBookId = book.id.trim();

    if (cleanLibId.isEmpty || cleanBookId.isEmpty) {
      throw ArgumentError('libraryId i book.id són obligatoris');
    }

    final booksColl = _booksRef(cleanLibId);
    if (booksColl == null || _firestore == null) {
      throw StateError('FirebaseFirestore no està disponible');
    }

    final batch = _firestore!.batch();
    batch.update(booksColl.doc(cleanBookId), book.toMap());

    // Si canvia de moble d'estanteria, ajustem els comptadors bookCount de tots dos
    if (oldBookcaseId != null &&
        oldBookcaseId.trim().isNotEmpty &&
        book.bookcaseId != null &&
        book.bookcaseId!.trim().isNotEmpty &&
        oldBookcaseId.trim() != book.bookcaseId!.trim()) {
      final oldBcDoc = _bookcasesRef(cleanLibId)?.doc(oldBookcaseId.trim());
      if (oldBcDoc != null) {
        batch.set(
          oldBcDoc,
          {'bookCount': FieldValue.increment(-1)},
          SetOptions(merge: true),
        );
      }
      final newBcDoc = _bookcasesRef(cleanLibId)?.doc(book.bookcaseId!.trim());
      if (newBcDoc != null) {
        batch.set(
          newBcDoc,
          {'bookCount': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
    return book;
  }
}
