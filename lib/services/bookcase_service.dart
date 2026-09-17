import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/book_model.dart';
import '../models/bookcase_model.dart';
import '../models/detected_book_spine.dart';

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

  /// Actualitza les dades d'un moble d'estanteria (nom i habitació opcional)
  Future<void> updateBookcase(
    String libraryId,
    String bookcaseId, {
    required String name,
    String? room,
  }) async {
    final cleanLibId = libraryId.trim();
    final cleanBookcaseId = bookcaseId.trim();
    final cleanName = name.trim();

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

    final updates = <String, dynamic>{
      'name': cleanName,
      if (room != null && room.trim().isNotEmpty) 'room': room.trim(),
    };

    await collection.doc(cleanBookcaseId).update(updates);
  }

  /// Actualitza el nom d'un moble d'estanteria
  Future<void> updateBookcaseName(String libraryId, String bookcaseId, String newName) {
    return updateBookcase(libraryId, bookcaseId, name: newName);
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

  /// Retorna un Stream de tots els llibres de la biblioteca sencera (útil per a cercadors)
  Stream<List<BookModel>> getAllBooks(String libraryId) {
    final cleanLibId = libraryId.trim();
    if (cleanLibId.isEmpty) {
      return Stream.value([]);
    }

    final booksColl = _booksRef(cleanLibId);
    if (booksColl == null) {
      return Stream.value([]);
    }

    return booksColl.snapshots().map((snapshot) {
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

  /// Consulta els llibres d'una balda específica d'un moble
  Future<List<BookModel>> getBooksForShelf(
    String libraryId,
    String bookcaseId,
    int shelfIndex,
  ) async {
    final cleanLibId = libraryId.trim();
    final cleanBcId = bookcaseId.trim();
    if (cleanLibId.isEmpty || cleanBcId.isEmpty) {
      return [];
    }

    final booksColl = _booksRef(cleanLibId);
    if (booksColl == null) return [];

    final targetShelfCode = '$cleanBcId-B$shelfIndex';
    final querySnap = await booksColl
        .where('shelfCode', isEqualTo: targetShelfCode)
        .get();

    final books = querySnap.docs
        .map((doc) => BookModel.fromMap(doc.data(), doc.id))
        .toList();
    books.sort((a, b) => a.positionIndex.compareTo(b.positionIndex));
    return books;
  }

  /// Buida tots els llibres d'una balda d'un moble i decrementa bookCount
  Future<void> clearShelf(
    String libraryId,
    String bookcaseId,
    int shelfIndex,
  ) async {
    final cleanLibId = libraryId.trim();
    final cleanBcId = bookcaseId.trim();
    if (cleanLibId.isEmpty || cleanBcId.isEmpty) {
      throw ArgumentError('libraryId i bookcaseId són obligatoris');
    }

    final booksColl = _booksRef(cleanLibId);
    if (booksColl == null || _firestore == null) {
      throw StateError('FirebaseFirestore no està disponible');
    }

    final targetShelfCode = '$cleanBcId-B$shelfIndex';
    final querySnap = await booksColl
        .where('shelfCode', isEqualTo: targetShelfCode)
        .get();

    if (querySnap.docs.isEmpty) {
      return;
    }

    final batch = _firestore!.batch();
    for (final doc in querySnap.docs) {
      batch.delete(doc.reference);
    }

    final bcDoc = _bookcasesRef(cleanLibId)?.doc(cleanBcId);
    if (bcDoc != null) {
      batch.set(
        bcDoc,
        {'bookCount': FieldValue.increment(-querySnap.docs.length)},
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  /// Puja la foto de la balda a Firebase Storage i desa en batch tots els llibres detectats a Firestore.
  /// Si [replaceExisting] és true, elimina prèviament els llibres existents a aquesta balda i ajusta bookCount.
  Future<List<BookModel>> saveCatalogedShelf({
    required String libraryId,
    required BookcaseModel bookcase,
    required int shelfIndex,
    required Uint8List imageBytes,
    required List<DetectedBookSpine> detectedBooks,
    bool replaceExisting = false,
    FirebaseStorage? storageInstance,
  }) async {
    final cleanLibId = libraryId.trim();
    if (cleanLibId.isEmpty) {
      throw ArgumentError('libraryId no pot estar buit');
    }

    final booksColl = _booksRef(cleanLibId);
    if (booksColl == null || _firestore == null) {
      throw StateError('FirebaseFirestore no està disponible');
    }

    String? photoUrl;
    try {
      final storage = storageInstance ?? FirebaseStorage.instance;
      final storageRef = storage
          .ref()
          .child('libraries/$cleanLibId/shelves/${bookcase.id}_shelf_$shelfIndex.jpg');

      final uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      photoUrl = downloadUrl;
    } catch (e) {
      debugPrint('No s\'ha pogut pujar la imatge a Storage (continuant amb desat de llibres): $e');
    }

    final batch = _firestore!.batch();
    int deletedCount = 0;

    if (replaceExisting) {
      final targetShelfCode = '${bookcase.id}-B$shelfIndex';
      final existingDocs = await booksColl
          .where('shelfCode', isEqualTo: targetShelfCode)
          .get();
      for (final doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }
      deletedCount = existingDocs.docs.length;
    }

    final now = DateTime.now();
    final List<BookModel> savedBooks = [];

    for (int i = 0; i < detectedBooks.length; i++) {
      final spine = detectedBooks[i];
      final docRef = booksColl.doc();
      final book = BookModel(
        id: docRef.id,
        title: spine.title,
        author: spine.author ?? '',
        shelfCode: '${bookcase.id}-B$shelfIndex',
        bookcaseId: bookcase.id,
        positionIndex: i + 1,
        photoUrl: photoUrl,
        box: spine.box,
        createdAt: now,
      );
      batch.set(docRef, book.toMap());
      savedBooks.add(book);
    }

    final netDiff = savedBooks.length - deletedCount;
    if (netDiff != 0) {
      final bookcaseDoc = _bookcasesRef(cleanLibId)?.doc(bookcase.id);
      if (bookcaseDoc != null) {
        batch.set(
          bookcaseDoc,
          {'bookCount': FieldValue.increment(netDiff)},
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
    return savedBooks;
  }

  /// Actualitza l'ordre ordinal (positionIndex: 1, 2, 3...) d'una llista de llibres d'una balda en batch a Firestore
  Future<void> updateShelfBooksOrder({
    required String libraryId,
    required List<BookModel> books,
  }) async {
    final cleanLibId = libraryId.trim();
    if (cleanLibId.isEmpty) {
      throw ArgumentError('libraryId no pot estar buit');
    }
    if (books.isEmpty) {
      return;
    }

    final booksColl = _booksRef(cleanLibId);
    if (booksColl == null || _firestore == null) {
      throw StateError('FirebaseFirestore no està disponible');
    }

    final batch = _firestore!.batch();
    for (int i = 0; i < books.length; i++) {
      final book = books[i];
      if (book.id.trim().isNotEmpty) {
        batch.update(
          booksColl.doc(book.id.trim()),
          {'positionIndex': i + 1},
        );
      }
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('BookcaseService: Error en actualitzar ordre dels llibres de la balda: $e');
      rethrow;
    }
  }

  /// Actualitza de manera retroactiva els llibres d'una balda utilitzant la foto existent.
  /// Sincronitza en un únic WriteBatch:
  /// 1. Elimina els llibres que s'han suprimit a la revisió.
  /// 2. Actualitza els llibres existents (títol, autor, ordre, caixa, photoUrl).
  /// 3. Crea documents nous per als llibres afegits manualment durant la revisió.
  /// 4. Ajusta atòmicament el camp `bookCount` del moble si hi ha diferència neta.
  Future<List<BookModel>> updateRetroactiveShelf({
    required String libraryId,
    required String shelfCode,
    required List<BookModel> updatedBooks,
    String? bookcaseId,
  }) async {
    final cleanLibId = libraryId.trim();
    final cleanShelfCode = shelfCode.trim();

    if (cleanLibId.isEmpty || cleanShelfCode.isEmpty) {
      throw ArgumentError('libraryId i shelfCode són obligatoris');
    }

    final booksColl = _booksRef(cleanLibId);
    if (booksColl == null || _firestore == null) {
      throw StateError('FirebaseFirestore no està disponible');
    }

    // 1. Obtenim els llibres actualment persistits a aquesta balda
    final existingQuerySnap = await booksColl
        .where('shelfCode', isEqualTo: cleanShelfCode)
        .get();
    final existingDocs = existingQuerySnap.docs;

    // Deducció de bookcaseId si no es passa explícitament
    String? targetBcId = bookcaseId?.trim();
    if (targetBcId == null || targetBcId.isEmpty) {
      final match = RegExp(r'^(.*)-B\d+$').firstMatch(cleanShelfCode);
      if (match != null) {
        targetBcId = match.group(1);
      } else {
        targetBcId = updatedBooks.cast<BookModel?>().firstWhere(
          (b) => b?.bookcaseId != null && b!.bookcaseId!.trim().isNotEmpty,
          orElse: () => null,
        )?.bookcaseId;
        if (targetBcId == null && existingDocs.isNotEmpty) {
          targetBcId = existingDocs.first.data()['bookcaseId'] as String?;
        }
      }
    }

    final batch = _firestore!.batch();

    // 2. Identifiquem els llibres esborrats
    final updatedIds = updatedBooks
        .map((b) => b.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final doc in existingDocs) {
      if (!updatedIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

    // 3. Persistim els llibres actualitzats i nous
    final List<BookModel> savedBooks = [];
    final now = DateTime.now();

    for (int i = 0; i < updatedBooks.length; i++) {
      final book = updatedBooks[i];
      final isNew = book.id.trim().isEmpty || !existingDocs.any((d) => d.id == book.id.trim());
      final docRef = isNew && book.id.trim().isEmpty
          ? booksColl.doc()
          : booksColl.doc(book.id.trim());

      final bookToSave = book.copyWith(
        id: docRef.id,
        shelfCode: cleanShelfCode,
        bookcaseId: book.bookcaseId ?? targetBcId,
        positionIndex: i + 1,
        createdAt: isNew && book.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
            ? now
            : book.createdAt,
      );

      batch.set(docRef, bookToSave.toMap(), SetOptions(merge: true));
      savedBooks.add(bookToSave);
    }

    // 4. Actualitzem el comptador del moble si hi ha variació neta
    final netDiff = updatedBooks.length - existingDocs.length;
    if (netDiff != 0 && targetBcId != null && targetBcId.isNotEmpty) {
      final bookcaseDoc = _bookcasesRef(cleanLibId)?.doc(targetBcId);
      if (bookcaseDoc != null) {
        batch.set(
          bookcaseDoc,
          {'bookCount': FieldValue.increment(netDiff)},
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
    return savedBooks;
  }
}
