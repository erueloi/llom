import 'package:cloud_firestore/cloud_firestore.dart';

/// Rols possibles per als membres d'una biblioteca
enum Role {
  owner,
  editor,
  viewer,
  none;

  static Role fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'owner':
        return Role.owner;
      case 'editor':
        return Role.editor;
      case 'viewer':
        return Role.viewer;
      default:
        return Role.none;
    }
  }

  String toRoleString() {
    switch (this) {
      case Role.owner:
        return 'owner';
      case Role.editor:
        return 'editor';
      case Role.viewer:
        return 'viewer';
      case Role.none:
        return 'none';
    }
  }
}

class LibraryModel {
  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;
  final Map<String, String> members;
  final List<String> memberUids;
  final DateTime createdAt;

  const LibraryModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.members,
    required this.memberUids,
    required this.createdAt,
  });

  /// Retorna el rol d'un usuari concret a la biblioteca
  Role getUserRole(String uid) {
    final roleString = members[uid];
    if (roleString != null) {
      return Role.fromString(roleString);
    }
    if (uid == ownerId) {
      return Role.owner;
    }
    return Role.none;
  }

  /// Converteix el model en un Map compatible amb Cloud Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'inviteCode': inviteCode,
      'members': members,
      'memberUids': memberUids,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Crea una instància de LibraryModel a partir d'un document de Firestore
  factory LibraryModel.fromMap(Map<String, dynamic> map, [String? id]) {
    final rawMembers = map['members'];
    final Map<String, String> parsedMembers = {};
    if (rawMembers is Map) {
      rawMembers.forEach((key, value) {
        if (key != null && value != null) {
          parsedMembers[key.toString()] = value.toString();
        }
      });
    }

    final rawMemberUids = map['memberUids'];
    final List<String> parsedMemberUids = [];
    if (rawMemberUids is List) {
      for (final item in rawMemberUids) {
        if (item != null) {
          parsedMemberUids.add(item.toString());
        }
      }
    } else {
      // Fallback a partir de les claus del mapa members i ownerId
      parsedMemberUids.addAll(parsedMembers.keys);
      final owner = map['ownerId'] as String?;
      if (owner != null && !parsedMemberUids.contains(owner)) {
        parsedMemberUids.add(owner);
      }
    }

    return LibraryModel(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      inviteCode: map['inviteCode'] as String? ?? '',
      members: parsedMembers,
      memberUids: parsedMemberUids,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  /// Retorna una còpia del model amb els camps actualitzats
  LibraryModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? inviteCode,
    Map<String, String>? members,
    List<String>? memberUids,
    DateTime? createdAt,
  }) {
    return LibraryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      inviteCode: inviteCode ?? this.inviteCode,
      members: members ?? Map<String, String>.from(this.members),
      memberUids: memberUids ?? List<String>.from(this.memberUids),
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LibraryModel || runtimeType != other.runtimeType) return false;

    if (id != other.id ||
        name != other.name ||
        ownerId != other.ownerId ||
        inviteCode != other.inviteCode ||
        createdAt != other.createdAt ||
        members.length != other.members.length ||
        memberUids.length != other.memberUids.length) {
      return false;
    }

    for (final key in members.keys) {
      if (members[key] != other.members[key]) {
        return false;
      }
    }

    for (int i = 0; i < memberUids.length; i++) {
      if (!other.memberUids.contains(memberUids[i])) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      ownerId.hashCode ^
      inviteCode.hashCode ^
      members.length.hashCode ^
      memberUids.length.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'LibraryModel(id: $id, name: $name, ownerId: $ownerId, inviteCode: $inviteCode, members: $members, memberUids: $memberUids, createdAt: $createdAt)';
  }
}
