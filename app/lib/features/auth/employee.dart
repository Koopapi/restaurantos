import 'package:flutter/material.dart';

/// Empleado autenticado (el backend nunca envía el PIN).
@immutable
class Employee {
  final String id;
  final String name;
  final String role; // mesero | cocina | barista | hostess | gerente | admin
  final String? initials;
  final String? color;
  final String? shift;

  const Employee({
    required this.id,
    required this.name,
    required this.role,
    this.initials,
    this.color,
    this.shift,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        initials: json['initials'] as String?,
        color: json['color'] as String?,
        shift: json['shift'] as String?,
      );

  /// Color de avatar parseado desde "#RRGGBB" (fallback al primary del tema).
  Color? get avatarColor {
    final c = color;
    if (c == null || !c.startsWith('#') || c.length != 7) return null;
    return Color(int.parse('FF${c.substring(1)}', radix: 16));
  }
}
