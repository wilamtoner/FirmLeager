import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/debt_provider.dart';
import '../providers/firm_provider.dart';
import '../utils/debt_calculator.dart';
import '../utils/formatters.dart';

class DebtPayoffScreen extends ConsumerStatefulWidget {
  const DebtPayoffScreen({super.key});

  @override
  ConsumerState<DebtPayoffScreen> createState() => _DebtPayoffScreenState();
}

class _DebtPayoffScreenState extends ConsumerState<DebtPayoffScreen> {
  double _extraBudget = 200.0;

  @override
  Widget build(BuildContext context) {
    final debts = ref.watch(debtProvider);
    final firm = ref.watch(firmProvider);
    final symbol = firm.currencySymbol;
    final activeDebts = debts.where((d) => d.isOwedByMe && d.currentBalance > 0).toList();

    final snowball = DebtCalculator.calculatePayoff(
      debts: debts,
      extraMonthlyBudget: _extraBudget,
      strategy: PayoffStrategy.snowball,
    );

    final avalanche = DebtCalculator.calculatePayoff(
      debts: debts,
      extraMonthlyBudget: _extraBudget,
      strategy: PayoffStrategy.avalanche,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Payoff Strategy Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Extra Monthly Payment Budget: ${Formatters.currency(_extraBudget, symbol)}',
                        style: Theme.of(context).textTheme.titleMedium),
                    Slider(
                      value: _extraBudget,
                      min: 0,
                      max: 1000,
                      divisions: 20,
                      label: Formatters.currency(_extraBudget, symbol),
                      onChanged: (val) => setState(() => _extraBudget = val),
                    ),
                    Text(
                      'Adjust slider to see how extra monthly payments reduce your payoff time and interest.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Strategy Comparison', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStrategyCard(
                    context,
                    title: 'Debt Snowball',
                    subtitle: 'Lowest Balance First',
                    result: snowball,
                    color: Colors.blue,
                    symbol: symbol,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStrategyCard(
                    context,
                    title: 'Debt Avalanche',
                    subtitle: 'Highest APR First',
                    result: avalanche,
                    color: Colors.deepOrange,
                    symbol: symbol,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Active Debt Payoff Sequence', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            activeDebts.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No active debts owed. You are debt-free!'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeDebts.length,
                    itemBuilder: (ctx, idx) {
                      final d = activeDebts[idx];
                      return Card(
                        child: ListTile(
                          title: Text(d.title),
                          subtitle: Text(
                            d.apr == 0 && d.minMonthlyPayment == 0
                                ? '0% Interest | Flexible Payoff'
                                : d.apr == 0
                                    ? '0% Interest | Min: ${Formatters.currency(d.minMonthlyPayment, symbol)}/mo'
                                    : d.minMonthlyPayment == 0
                                        ? 'APR: ${d.apr.toStringAsFixed(1)}% | Flexible Payoff'
                                        : 'APR: ${d.apr.toStringAsFixed(1)}% | Min: ${Formatters.currency(d.minMonthlyPayment, symbol)}/mo',
                          ),
                          trailing: Text(Formatters.currency(d.currentBalance, symbol),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required DebtPayoffResult result,
    required Color color,
    required String symbol,
  }) {
    return Card(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const Divider(),
            const SizedBox(height: 4),
            Text('Payoff Time:', style: Theme.of(context).textTheme.bodySmall),
            Text('${(result.totalMonths / 12).toStringAsFixed(1)} Years (${result.totalMonths} mos)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Total Interest Paid:', style: Theme.of(context).textTheme.bodySmall),
            Text(Formatters.currency(result.totalInterestPaid, symbol),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red[700])),
          ],
        ),
      ),
    );
  }
}
