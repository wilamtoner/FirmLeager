import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/debt.dart';
import '../models/debt_payment.dart';
import '../services/database_service.dart';

final debtProvider = StateNotifierProvider<DebtNotifier, List<DebtModel>>((ref) {
  return DebtNotifier();
});

class DebtNotifier extends StateNotifier<List<DebtModel>> {
  DebtNotifier() : super([]) {
    loadDebts();
  }

  final DatabaseService _db = DatabaseService();

  Future<void> loadDebts() async {
    final list = await _db.getDebts();
    state = list;
  }

  Future<void> addDebt(DebtModel debt) async {
    await _db.insertDebt(debt);
    await loadDebts();
  }

  Future<void> logPayment({
    required String debtId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    final debt = state.firstWhere((d) => d.id == debtId);
    double newBalance = debt.currentBalance - amount;
    if (newBalance < 0) newBalance = 0;

    await _db.updateDebtBalance(debtId, newBalance);

    final payment = DebtPaymentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      debtId: debtId,
      amount: amount,
      date: date,
      notes: notes,
    );
    await _db.insertDebtPayment(payment);

    await loadDebts();
  }

  Future<void> deleteDebt(String id) async {
    await _db.deleteDebt(id);
    await loadDebts();
  }
}
