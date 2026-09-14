import 'package:flutter/material.dart';

class ShelfUnit {
  final String id;
  final String name;
  final String location;
  final int shelfCount;
  final int bookCount;
  final IconData icon;

  const ShelfUnit({
    required this.id,
    required this.name,
    this.location = '',
    required this.shelfCount,
    required this.bookCount,
    this.icon = Icons.shelves,
  });

  /// Còpia amb camps modificats
  ShelfUnit copyWith({
    String? id,
    String? name,
    String? location,
    int? shelfCount,
    int? bookCount,
    IconData? icon,
  }) {
    return ShelfUnit(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      shelfCount: shelfCount ?? this.shelfCount,
      bookCount: bookCount ?? this.bookCount,
      icon: icon ?? this.icon,
    );
  }
}
