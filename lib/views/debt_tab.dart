import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/debt_provider.dart';
import '../providers/firm_provider.dart';
import '../models/debt.dart';
import '../utils/formatters.dart';
import 'add_debt_dialog.dart';
import 'debt_payoff_screen.dart';

class DebtTab extends ConsumerWidget {
  const DebtTab({super.key});

  static const Color darkGreen = Color(0xFF064E3B);

  void _showPaymentDialog(BuildContext context, WidgetRef ref, DebtModel debt, String symbol) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Payment for ${debt.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Balance: ${Formatters.currency(debt.currentBalance, symbol)}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Payment Amount ($symbol)', border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final amt = double.tryParse(amountController.text);
              if (amt != null && amt > 0) {
                ref.read(debtProvider.notifier).logPayment(
                      debtId: debt.id,
                      amount: amt,
                      date: DateTime.now(),
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Confirm Payment'),
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
            // Strategy Banner Card
            Card(
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.calculate, color: Colors.indigo, size: 36),
                title: const Text('Debt Payoff Strategy Calculator', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Simulate Snowball vs Avalanche payoff methods'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const DebtPayoffScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

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
                                  Text(d.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(Formatters.currency(d.currentBalance, symbol), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${d.partyName} • APR: ${d.apr.toStringAsFixed(1)}% • Min: ${Formatters.currency(d.minMonthlyPayment, symbol)}/mo'),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(value: paidPct, backgroundColor: Colors.grey[300], color: Colors.green),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${(paidPct * 100).toStringAsFixed(0)}% Paid Off'),
                                  ElevatedButton.icon(
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(d.title),
                          subtitle: Text('Borrower: ${d.partyName}'),
                          trailing: Text(Formatters.currency(d.currentBalance, symbol), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_debt_tab',
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        onPressed: () {
          showDialog(context: context, builder: (ctx) => const AddDebtDialog());
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Debt'),
      ),
    );
  }
}
