import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/withdrawal.dart';

class WithdrawalRepository {
  final FirebaseFirestore _db;
  final String _uid;

  WithdrawalRepository(this._uid) : _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('withdrawals');

  Future<List<Withdrawal>> getByInvestmentId(String investmentId) async {
    final snap = await _col
        .where('investment_id', isEqualTo: investmentId)
        .get();
    final list = snap.docs.map(Withdrawal.fromFirestore).toList()
      ..sort((a, b) => b.withdrawalDate.compareTo(a.withdrawalDate));
    return list;
  }

  Future<String> insert(Withdrawal withdrawal) async {
    final ref = await _col.add(withdrawal.toFirestore());
    return ref.id;
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<double> getTotalForInvestment(String investmentId) async {
    final snap = await _col
        .where('investment_id', isEqualTo: investmentId)
        .get();
    return snap.docs.fold<double>(0.0, (acc, d) => acc + (d['amount'] as num).toDouble());
  }
}
