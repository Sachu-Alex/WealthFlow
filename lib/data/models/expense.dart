import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String? id;
  final String category;
  final int categoryColor;
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const Expense({
    this.id,
    required this.category,
    required this.categoryColor,
    required this.amount,
    this.note,
    required this.date,
    required this.createdAt,
  });

  Color get color => Color(categoryColor);

  Expense copyWith({
    String? id,
    String? category,
    int? categoryColor,
    double? amount,
    Object? note = _sentinel,
    DateTime? date,
    DateTime? createdAt,
  }) =>
      Expense(
        id: id ?? this.id,
        category: category ?? this.category,
        categoryColor: categoryColor ?? this.categoryColor,
        amount: amount ?? this.amount,
        note: note == _sentinel ? this.note : note as String?,
        date: date ?? this.date,
        createdAt: createdAt ?? this.createdAt,
      );

  static const _sentinel = Object();

  Map<String, dynamic> toFirestore() => {
        'category': category,
        'category_color': categoryColor,
        'amount': amount,
        'note': note,
        'date': Timestamp.fromDate(date),
        'created_at': Timestamp.fromDate(createdAt),
      };

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      category: data['category'] as String,
      categoryColor: data['category_color'] as int,
      amount: (data['amount'] as num).toDouble(),
      note: data['note'] as String?,
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }
}

// ─── Category definitions ────────────────────────────────────────────────────

class ExpenseCategory {
  final String name;
  final String emoji;
  final IconData icon;
  final Color color;
  final List<double> amountPresets;

  const ExpenseCategory({
    required this.name,
    required this.emoji,
    required this.icon,
    required this.color,
    required this.amountPresets,
  });
}

const kExpenseCategories = <ExpenseCategory>[
  ExpenseCategory(
    name: 'Food',
    emoji: '🍽️',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFF59E0B),
    amountPresets: [50, 100, 200, 500, 1000],
  ),
  ExpenseCategory(
    name: 'Shopping',
    emoji: '🛍️',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFF8B5CF6),
    amountPresets: [500, 1000, 2000, 5000, 10000],
  ),
  ExpenseCategory(
    name: 'Groceries',
    emoji: '🛒',
    icon: Icons.local_grocery_store_rounded,
    color: Color(0xFF10B981),
    amountPresets: [100, 200, 500, 1000, 2000],
  ),
  ExpenseCategory(
    name: 'Health',
    emoji: '💊',
    icon: Icons.medical_services_rounded,
    color: Color(0xFFEF4444),
    amountPresets: [50, 100, 200, 500, 1000],
  ),
  ExpenseCategory(
    name: 'Fuel',
    emoji: '⛽',
    icon: Icons.local_gas_station_rounded,
    color: Color(0xFF3B82F6),
    amountPresets: [200, 500, 1000, 2000, 3000],
  ),
  ExpenseCategory(
    name: 'Entertainment',
    emoji: '🎬',
    icon: Icons.movie_rounded,
    color: Color(0xFFEC4899),
    amountPresets: [100, 200, 500, 1000, 2000],
  ),
  ExpenseCategory(
    name: 'Travel',
    emoji: '✈️',
    icon: Icons.flight_takeoff_rounded,
    color: Color(0xFF06B6D4),
    amountPresets: [500, 1000, 2000, 5000, 10000],
  ),
  ExpenseCategory(
    name: 'Bills',
    emoji: '📄',
    icon: Icons.receipt_long_rounded,
    color: Color(0xFFF97316),
    amountPresets: [500, 1000, 2000, 5000, 10000],
  ),
  ExpenseCategory(
    name: 'Education',
    emoji: '📚',
    icon: Icons.school_rounded,
    color: Color(0xFF6366F1),
    amountPresets: [200, 500, 1000, 2000, 5000],
  ),
  ExpenseCategory(
    name: 'Others',
    emoji: '📦',
    icon: Icons.more_horiz_rounded,
    color: Color(0xFF94A3B8),
    amountPresets: [100, 200, 500, 1000, 2000],
  ),
];

ExpenseCategory? categoryByName(String name) {
  try {
    return kExpenseCategories.firstWhere((c) => c.name == name);
  } catch (_) {
    return null;
  }
}
