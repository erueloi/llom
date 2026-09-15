import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'shelf_unit_model.dart';

/// Model de dades d'un moble d'estanteria associat a una biblioteca
class BookcaseModel {
  final String id;
  final String name;
  final String room;
  final int shelfCount;
  final int bookCount;
  final DateTime createdAt;

  const BookcaseModel({
    required this.id,
    required this.name,
    required this.room,
    required this.shelfCount,
    this.bookCount = 0,
    required this.createdAt,
  });

  /// Converteix el model a mapa serialitzable per a Cloud Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'room': room,
      'shelfCount': shelfCount,
      'bookCount': bookCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Construeix una instància a partir d'un document de Firestore
  factory BookcaseModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseCreatedAt(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return BookcaseModel(
      id: id,
      name: map['name'] as String? ?? '',
      room: map['room'] as String? ?? '',
      shelfCount: (map['shelfCount'] as num?)?.toInt() ?? 4,
      bookCount: (map['bookCount'] as num?)?.toInt() ?? 0,
      createdAt: parseCreatedAt(map['createdAt']),
    );
  }

  /// Còpia amb camps modificats
  BookcaseModel copyWith({
    String? id,
    String? name,
    String? room,
    int? shelfCount,
    int? bookCount,
    DateTime? createdAt,
  }) {
    return BookcaseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      room: room ?? this.room,
      shelfCount: shelfCount ?? this.shelfCount,
      bookCount: bookCount ?? this.bookCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converteix a ShelfUnit per a la integració directa amb BookcaseCard i BookcaseCarousel
  ShelfUnit toShelfUnit() {
    return ShelfUnit(
      id: id,
      name: name,
      location: room,
      shelfCount: shelfCount,
      bookCount: bookCount,
      icon: Icons.shelves,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookcaseModel &&
        other.id == id &&
        other.name == name &&
        other.room == room &&
        other.shelfCount == shelfCount &&
        other.bookCount == bookCount &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, name, room, shelfCount, bookCount, createdAt);

  @override
  String toString() {
    return 'BookcaseModel(id: $id, name: $name, room: $room, shelfCount: $shelfCount, bookCount: $bookCount)';
  }
}
