import 'package:cloud_firestore/cloud_firestore.dart';

/// Registre individual d'un préstec d'un llibre a l'historial
class LoanRecord {
  final String id;
  final String borrowedTo;
  final DateTime borrowedAt;
  final DateTime? returnedAt;

  const LoanRecord({
    required this.id,
    required this.borrowedTo,
    required this.borrowedAt,
    this.returnedAt,
  });

  /// Durada del préstec en dies. Si continua actiu, calcula els dies transcorreguts fins avui.
  int get durationInDays {
    final end = returnedAt ?? DateTime.now();
    final diff = end.difference(borrowedAt).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Converteix el registre en un Map compatible amb Cloud Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'borrowedTo': borrowedTo,
      'borrowedAt': Timestamp.fromDate(borrowedAt),
      if (returnedAt != null) 'returnedAt': Timestamp.fromDate(returnedAt!),
    };
  }

  /// Crea una instància de LoanRecord a partir d'un Map de Firestore o memòria
  factory LoanRecord.fromMap(Map<String, dynamic> map, [String? id]) {
    return LoanRecord(
      id: id ?? (map['id'] as String? ?? ''),
      borrowedTo: map['borrowedTo'] as String? ?? 'En lectura',
      borrowedAt: _parseDateTime(map['borrowedAt']),
      returnedAt: map['returnedAt'] != null ? _parseDateTime(map['returnedAt']) : null,
    );
  }

  LoanRecord copyWith({
    String? id,
    String? borrowedTo,
    DateTime? borrowedAt,
    DateTime? returnedAt,
  }) {
    return LoanRecord(
      id: id ?? this.id,
      borrowedTo: borrowedTo ?? this.borrowedTo,
      borrowedAt: borrowedAt ?? this.borrowedAt,
      returnedAt: returnedAt ?? this.returnedAt,
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
    return other is LoanRecord &&
        other.id == id &&
        other.borrowedTo == borrowedTo &&
        other.borrowedAt == borrowedAt &&
        other.returnedAt == returnedAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      borrowedTo.hashCode ^
      borrowedAt.hashCode ^
      returnedAt.hashCode;

  @override
  String toString() {
    return 'LoanRecord(id: $id, borrowedTo: $borrowedTo, borrowedAt: $borrowedAt, returnedAt: $returnedAt)';
  }
}
