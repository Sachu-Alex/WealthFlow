import 'package:cloud_firestore/cloud_firestore.dart';

class Investment {
  final String? id;
  final String investorName;
  final double initialAmount;
  final DateTime investmentDate;
  final String? notes;
  final DateTime createdAt;

  const Investment({
    this.id,
    required this.investorName,
    required this.initialAmount,
    required this.investmentDate,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
        'investor_name': investorName,
        'initial_amount': initialAmount,
        'investment_date': Timestamp.fromDate(investmentDate),
        'notes': notes,
        'created_at': Timestamp.fromDate(createdAt),
      };

  factory Investment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Investment(
      id: doc.id,
      investorName: data['investor_name'] as String,
      initialAmount: (data['initial_amount'] as num).toDouble(),
      investmentDate: (data['investment_date'] as Timestamp).toDate(),
      notes: data['notes'] as String?,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Investment copyWith({
    String? id,
    String? investorName,
    double? initialAmount,
    DateTime? investmentDate,
    String? notes,
    DateTime? createdAt,
  }) =>
      Investment(
        id: id ?? this.id,
        investorName: investorName ?? this.investorName,
        initialAmount: initialAmount ?? this.initialAmount,
        investmentDate: investmentDate ?? this.investmentDate,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
}
