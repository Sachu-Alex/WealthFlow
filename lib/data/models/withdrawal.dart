import 'package:cloud_firestore/cloud_firestore.dart';

class Withdrawal {
  final String? id;
  final String investmentId;
  final double amount;
  final DateTime withdrawalDate;
  final String? remarks;
  final DateTime createdAt;

  const Withdrawal({
    this.id,
    required this.investmentId,
    required this.amount,
    required this.withdrawalDate,
    this.remarks,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
        'investment_id': investmentId,
        'amount': amount,
        'withdrawal_date': Timestamp.fromDate(withdrawalDate),
        'remarks': remarks,
        'created_at': Timestamp.fromDate(createdAt),
      };

  factory Withdrawal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Withdrawal(
      id: doc.id,
      investmentId: data['investment_id'] as String,
      amount: (data['amount'] as num).toDouble(),
      withdrawalDate: (data['withdrawal_date'] as Timestamp).toDate(),
      remarks: data['remarks'] as String?,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }
}
