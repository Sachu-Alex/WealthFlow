import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment.dart';
import '../models/investment_with_stats.dart';

class InvestmentRepository {
  final FirebaseFirestore _db;
  final String _uid;

  InvestmentRepository(this._uid) : _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('investments');

  Future<List<Investment>> getAll() async {
    final snap = await _col.orderBy('created_at', descending: true).get();
    return snap.docs.map(Investment.fromFirestore).toList();
  }

  Future<Investment?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Investment.fromFirestore(doc);
  }

  Future<List<InvestmentWithStats>> getAllWithStats() async {
    final investments = await getAll();
    final withdrawalCol =
        _db.collection('users').doc(_uid).collection('withdrawals');

    return Future.wait(investments.map((inv) async {
      final snap = await withdrawalCol
          .where('investment_id', isEqualTo: inv.id)
          .get();
      final totalWithdrawn =
          snap.docs.fold(0.0, (acc, d) => acc + (d['amount'] as num).toDouble());
      return InvestmentWithStats(
        investment: inv,
        totalWithdrawn: totalWithdrawn,
        withdrawalCount: snap.docs.length,
      );
    }));
  }

  Future<String> insert(Investment investment) async {
    final ref = await _col.add(investment.toFirestore());
    return ref.id;
  }

  Future<void> update(Investment investment) async {
    await _col.doc(investment.id).update(investment.toFirestore());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
