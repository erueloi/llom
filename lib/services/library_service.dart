import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:llom/models/library_model.dart';

/// Excepció personalitzada per a errors relacionats amb la gestió de biblioteques
class LibraryException implements Exception {
  final String message;
  final String? code;

  const LibraryException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Servei per gestionar les biblioteques, membres i codis d'invitació a Cloud Firestore
class LibraryService {
  final FirebaseFirestore? _firestoreInstance;
  final String Function()? _codeGenerator;

  LibraryService({
    FirebaseFirestore? firestore,
    String Function()? codeGenerator,
  })  : _firestoreInstance = firestore,
        _codeGenerator = codeGenerator;

  FirebaseFirestore get _firestore => _firestoreInstance ?? FirebaseFirestore.instance;

  /// Genera un codi alfanumèric aleatori de 6 caràcters en majúscules (ex: "LM7K92")
  String generateInviteCode() => _generateInviteCode();

  String _generateInviteCode() {
    final generator = _codeGenerator;
    if (generator != null) {
      return generator();
    }
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Crea una nova biblioteca a Firestore i l'assigna com a activa a l'usuari propietari
  Future<LibraryModel> createLibrary({
    required String name,
    required String ownerUid,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const LibraryException('El nom de la biblioteca no pot estar buit.');
    }
    if (ownerUid.trim().isEmpty) {
      throw const LibraryException("L'identificador de l'usuari propietari no és vàlid.");
    }

    try {
      final inviteCode = _generateInviteCode();
      final libRef = _firestore.collection('libraries').doc();
      final now = DateTime.now();

      final library = LibraryModel(
        id: libRef.id,
        name: trimmedName,
        ownerId: ownerUid,
        inviteCode: inviteCode,
        members: {ownerUid: 'owner'},
        memberUids: [ownerUid],
        createdAt: now,
      );

      // Transacció atòmica per crear la biblioteca i actualitzar l'usuari
      final batch = _firestore.batch();
      batch.set(libRef, library.toMap());

      final userRef = _firestore.collection('users').doc(ownerUid);
      batch.set(userRef, {'activeLibraryId': libRef.id}, SetOptions(merge: true));

      await batch.commit();

      return library;
    } catch (e) {
      if (e is LibraryException) rethrow;
      throw LibraryException(
        "S'ha produït un error en crear la biblioteca: ${e.toString()}",
      );
    }
  }

  /// Uneix un usuari a una biblioteca existent mitjançant el seu codi d'invitació
  Future<LibraryModel> joinLibraryByCode({
    required String inviteCode,
    required String uid,
    String defaultRole = 'viewer',
  }) async {
    final cleanCode = inviteCode.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      throw const LibraryException("El codi d'invitació no pot estar buit.");
    }
    if (uid.trim().isEmpty) {
      throw const LibraryException("L'identificador de l'usuari no és vàlid.");
    }

    try {
      final querySnapshot = await _firestore
          .collection('libraries')
          .where('inviteCode', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw const LibraryException(
          "No s'ha trobat cap biblioteca amb aquest codi d'invitació.",
        );
      }

      final libDoc = querySnapshot.docs.first;
      final currentLibrary = LibraryModel.fromMap(libDoc.data(), libDoc.id);

      // Si l'usuari ja n'és membre, simplement activem la biblioteca per a ell
      if (currentLibrary.memberUids.contains(uid)) {
        await _firestore.collection('users').doc(uid).set(
          {'activeLibraryId': currentLibrary.id},
          SetOptions(merge: true),
        );
        return currentLibrary;
      }

      // Transacció atòmica per afegir el membre i actualitzar la biblioteca activa
      final batch = _firestore.batch();
      batch.update(libDoc.reference, {
        'members.$uid': defaultRole,
        'memberUids': FieldValue.arrayUnion([uid]),
      });

      final userRef = _firestore.collection('users').doc(uid);
      batch.set(userRef, {'activeLibraryId': libDoc.id}, SetOptions(merge: true));

      await batch.commit();

      final updatedMembers = Map<String, String>.from(currentLibrary.members)
        ..[uid] = defaultRole;
      final updatedUids = List<String>.from(currentLibrary.memberUids);
      if (!updatedUids.contains(uid)) {
        updatedUids.add(uid);
      }

      return currentLibrary.copyWith(
        members: updatedMembers,
        memberUids: updatedUids,
      );
    } catch (e) {
      if (e is LibraryException) rethrow;
      throw LibraryException(
        "S'ha produït un error en unir-se a la biblioteca: ${e.toString()}",
      );
    }
  }

  /// Retorna un Stream escoltant les biblioteques on l'usuari és membre ordenades per data de creació
  Stream<List<LibraryModel>> getUserLibraries(String uid) {
    return _firestore
        .collection('libraries')
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final libraries = snapshot.docs
              .map((doc) => LibraryModel.fromMap(doc.data(), doc.id))
              .toList();
          libraries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return libraries;
        });
  }

  /// Actualitza el rol d'un membre si el sol·licitant és el propietari
  Future<void> updateMemberRole({
    required String libraryId,
    required String targetUid,
    required String newRole,
    required String requesterUid,
  }) async {
    try {
      final libDoc = await _firestore.collection('libraries').doc(libraryId).get();
      if (!libDoc.exists || libDoc.data() == null) {
        throw const LibraryException("No s'ha trobat la biblioteca especificada.");
      }

      final library = LibraryModel.fromMap(libDoc.data()!, libDoc.id);

      final requesterRole = library.getUserRole(requesterUid);
      if (requesterRole != Role.owner) {
        throw const LibraryException(
          'Només el propietari de la biblioteca pot modificar els rols dels membres.',
        );
      }

      if (targetUid == library.ownerId && newRole.trim().toLowerCase() != 'owner') {
        throw const LibraryException(
          'No es pot canviar el rol del propietari de la biblioteca.',
        );
      }

      if (!library.memberUids.contains(targetUid)) {
        throw const LibraryException(
          "L'usuari especificat no és membre d'aquesta biblioteca.",
        );
      }

      final normalizedRole = newRole.trim().toLowerCase();
      if (normalizedRole != 'owner' &&
          normalizedRole != 'editor' &&
          normalizedRole != 'viewer') {
        throw const LibraryException(
          "El rol indicat no és vàlid. Ha de ser 'owner', 'editor' o 'viewer'.",
        );
      }

      await libDoc.reference.update({
        'members.$targetUid': normalizedRole,
      });
    } catch (e) {
      if (e is LibraryException) rethrow;
      throw LibraryException(
        "S'ha produït un error en actualitzar el rol del membre: ${e.toString()}",
      );
    }
  }

  /// Expulsa o permet marxar voluntàriament a un membre de la biblioteca
  Future<void> removeMember({
    required String libraryId,
    required String targetUid,
    required String requesterUid,
  }) async {
    try {
      final libDoc = await _firestore.collection('libraries').doc(libraryId).get();
      if (!libDoc.exists || libDoc.data() == null) {
        throw const LibraryException("No s'ha trobat la biblioteca especificada.");
      }

      final library = LibraryModel.fromMap(libDoc.data()!, libDoc.id);

      final isOwner = library.getUserRole(requesterUid) == Role.owner;
      final isSelf = requesterUid == targetUid;

      if (!isOwner && !isSelf) {
        throw const LibraryException(
          'No tens permisos per expulsar aquest membre de la biblioteca.',
        );
      }

      if (targetUid == library.ownerId) {
        throw const LibraryException(
          'El propietari no pot abandonar ni ser expulsat de la seva biblioteca.',
        );
      }

      if (!library.memberUids.contains(targetUid)) {
        throw const LibraryException(
          "L'usuari especificat no és membre d'aquesta biblioteca.",
        );
      }

      final batch = _firestore.batch();
      batch.update(libDoc.reference, {
        'members.$targetUid': FieldValue.delete(),
        'memberUids': FieldValue.arrayRemove([targetUid]),
      });

      // Si la biblioteca eliminada era l'activa de l'usuari, es reinicia
      final userDoc = await _firestore.collection('users').doc(targetUid).get();
      if (userDoc.exists && userDoc.data()?['activeLibraryId'] == libraryId) {
        batch.update(userDoc.reference, {'activeLibraryId': null});
      }

      await batch.commit();
    } catch (e) {
      if (e is LibraryException) rethrow;
      throw LibraryException(
        "S'ha produït un error en eliminar el membre: ${e.toString()}",
      );
    }
  }

  /// Regenera el codi d'invitació de la biblioteca (només permès per al propietari)
  Future<String> regenerateInviteCode({
    required String libraryId,
    required String requesterUid,
  }) async {
    try {
      final libDoc = await _firestore.collection('libraries').doc(libraryId).get();
      if (!libDoc.exists || libDoc.data() == null) {
        throw const LibraryException("No s'ha trobat la biblioteca especificada.");
      }

      final library = LibraryModel.fromMap(libDoc.data()!, libDoc.id);
      if (library.getUserRole(requesterUid) != Role.owner) {
        throw const LibraryException(
          "Només el propietari pot regenerar el codi d'invitació.",
        );
      }

      final newCode = _generateInviteCode();
      await libDoc.reference.update({'inviteCode': newCode});
      return newCode;
    } catch (e) {
      if (e is LibraryException) rethrow;
      throw LibraryException(
        "S'ha produït un error en regenerar el codi d'invitació: ${e.toString()}",
      );
    }
  }
}
