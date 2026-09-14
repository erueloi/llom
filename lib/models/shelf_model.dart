import 'package:cloud_firestore/cloud_firestore.dart';

class ShelfModel {
  final String id;
  final String code;
  final String? photoUrl;
  final int bookCount;
  final DateTime createdAt;

  const ShelfModel({
    required this.id,
    required this.code,
    this.photoUrl,
    this.bookCount = 0,
    required this.createdAt,
  });

  /// Converteix el model en un Map compatible amb Cloud Firestore
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'photoUrl': photoUrl,
      'bookCount': bookCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Crea una instància de ShelfModel a partir d'un document de Firestore
  factory ShelfModel.fromMap(Map<String, dynamic> map, String id) {
    return ShelfModel(
      id: id,
      code: map['code'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      bookCount: (map['bookCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  /// Retorna una còpia del model amb els camps actualitzats
  ShelfModel copyWith({
    String? id,
    String? code,
    String? photoUrl,
    int? bookCount,
    DateTime? createdAt,
  }) {
    return ShelfModel(
      id: id ?? this.id,
      code: code ?? this.code,
      photoUrl: photoUrl ?? this.photoUrl,
      bookCount: bookCount ?? this.bookCount,
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
      other is ShelfModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          photoUrl == other.photoUrl &&
          bookCount == other.bookCount &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      code.hashCode ^
      photoUrl.hashCode ^
      bookCount.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'ShelfModel(id: $id, code: $code, photoUrl: $photoUrl, bookCount: $bookCount, createdAt: $createdAt)';
  }
}
