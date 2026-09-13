import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/debt_provider.dart';
import '../providers/firm_provider.dart';
import '../models/debt.dart';
import '../utils/formatters.dart';
import 'new_debt_screen.dart';
import '../theme/app_colors.dart';

class DebtTab extends ConsumerWidget {
  const DebtTab({super.key});

  static const Color brandPrimary = AppColors.primaryBlue;
  static const Color darkGreen = brandPrimary;

  void _showPaymentDialog(BuildContext context, WidgetRef ref, DebtModel debt, String symbol) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(debt.isOwedByMe ? 'Log Payment: ${debt.title}' : 'Record Repayment: ${debt.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Balance: ${Formatters.currency(debt.currentBalance, symbol)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: debt.isOwedByMe ? 'Payment Amount ($symbol)' : 'Amount Received ($symbol)',
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final amt = double.tryParse(amountController.text.replaceAll(',', '.').trim());
              if (amt != null && amt > 0) {
                ref.read(debtProvider.notifier).logPayment(
                      debtId: debt.id,
                      amount: amt,
                      date: DateTime.now(),
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: Text(debt.isOwedByMe ? 'Confirm Payment' : 'Confirm Receipt'),
          ),
        ],
      ),
    ).then((_) => amountController.dispose());
  }

  void _confirmDeleteDebt(BuildContext context, WidgetRef ref, DebtModel debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Debt Record'),
        content: Text('Are you sure you want to delete "${debt.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(debtProvider.notifier).deleteDebt(debt.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ref.watch(debtProvider);
    final firm = ref.watch(firmProvider);
    final symbol = firm.currencySymbol;
    final debtsIOwe = debts.where((d) => d.isOwedByMe).toList();
    final debtsOwedToMe = debts.where((d) => !d.isOwedByMe).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Action Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Debt & Loan Ledger',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const NewDebtScreen()),
                    );
                  },
                  child: const Text('Add Debt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Debts I Owe Section
            Text('Debts I Owe (Liabilities)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            debtsIOwe.isEmpty
                ? const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No active debts owed.')))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: debtsIOwe.length,
                    itemBuilder: (ctx, idx) {
                      final d = debtsIOwe[idx];
                      final paidPct = d.originalAmount > 0 ? ((d.originalAmount - d.currentBalance) / d.originalAmount).clamp(0.0, 1.0) : 0.0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(d.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                  Text(Formatters.currency(d.currentBalance, symbol), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                    tooltip: 'Delete debt',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _confirmDeleteDebt(context, ref, d),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(_formatDebtTerms(d, symbol)),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(value: paidPct, backgroundColor: Colors.grey[300], color: Colors.green),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${(paidPct * 100).toStringAsFixed(0)}% Paid Off'),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: darkGreen,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _showPaymentDialog(context, ref, d, symbol),
                                    icon: const Icon(Icons.payment, size: 16),
                                    label: const Text('Log Payment'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20),

            // Debts Owed to Me Section
            Text('Debts Owed to Me (Assets)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            debtsOwedToMe.isEmpty
                ? const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No debts owed to you.')))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: debtsOwedToMe.length,
                    itemBuilder: (ctx, idx) {
                      final d = debtsOwedToMe[idx];
                      final paidPct = d.originalAmount > 0 ? ((d.originalAmount - d.currentBalance) / d.originalAmount).clamp(0.0, 1.0) : 0.0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(d.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                  Text(Formatters.currency(d.currentBalance, symbol), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                    tooltip: 'Delete record',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _confirmDeleteDebt(context, ref, d),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                d.apr == 0 && d.minMonthlyPayment == 0
                                    ? 'Borrower: ${d.partyName} • 0% Interest • Flexible'
                                    : d.apr == 0
                                        ? 'Borrower: ${d.partyName} • 0% Interest'
                                        : 'Borrower: ${d.partyName} • APR: ${d.apr.toStringAsFixed(1)}%',
                              ),
                              if (d.originalAmount > 0) ...[
                                const SizedBox(height: 8),
                                LinearProgressIndicator(value: paidPct, backgroundColor: Colors.grey[300], color: Colors.green),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${(paidPct * 100).toStringAsFixed(0)}% Collected'),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: darkGreen,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _showPaymentDialog(context, ref, d, symbol),
                                    icon: const Icon(Icons.call_received, size: 16),
                                    label: const Text('Receive Payment'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  String _formatDebtTerms(DebtModel d, String symbol) {
    if (d.apr == 0 && d.minMonthlyPayment == 0) {
      return '${d.partyName} • 0% Interest (Interest-Free) • Flexible Payoff';
    } else if (d.apr == 0) {
      return '${d.partyName} • 0% Interest • Min: ${Formatters.currency(d.minMonthlyPayment, symbol)}/mo';
    } else if (d.minMonthlyPayment == 0) {
      return '${d.partyName} • APR: ${d.apr.toStringAsFixed(1)}% • Flexible Payoff';
    } else {
      return '${d.partyName} • APR: ${d.apr.toStringAsFixed(1)}% • Min: ${Formatters.currency(d.minMonthlyPayment, symbol)}/mo';
    }
  }
}
