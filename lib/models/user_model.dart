import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? activeLibraryId;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.activeLibraryId,
    required this.createdAt,
  });

  /// Converteix el model d'usuari en un Map compatible amb Cloud Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'activeLibraryId': activeLibraryId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Crea una instància de UserModel a partir d'un document de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map, [String? uid]) {
    return UserModel(
      uid: uid ?? map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      activeLibraryId: map['activeLibraryId'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  /// Retorna una còpia del model d'usuari amb els camps actualitzats
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? activeLibraryId,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      activeLibraryId: activeLibraryId ?? this.activeLibraryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          activeLibraryId == other.activeLibraryId &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      activeLibraryId.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, activeLibraryId: $activeLibraryId, createdAt: $createdAt)';
  }
}
