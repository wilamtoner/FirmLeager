import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/firm_provider.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

enum DetailCardType { income, expense, receivables, payables }

class CardDetailDialog extends ConsumerWidget {
  final DetailCardType cardType;
  final DateTimeRange? dateRange;

  const CardDetailDialog({super.key, required this.cardType, this.dateRange});

  static void showMobileBottomSheet(BuildContext context, DetailCardType type, {DateTimeRange? dateRange}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CardDetailDialog(cardType: type, dateRange: dateRange),
    );
  }

  String _getTitle() {
    switch (cardType) {
      case DetailCardType.income:
        return 'Income Transactions Breakdown';
      case DetailCardType.expense:
        return 'Expense Outflow Breakdown';
      case DetailCardType.receivables:
        return 'Receivables (Money To Collect)';
      case DetailCardType.payables:
        return 'Payables (Money Due)';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firm = ref.watch(firmProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Mobile Handle Bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getTitle(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            const Divider(height: 1),

            // Content List
            Expanded(
              child: _buildContent(context, ref, firm.currencySymbol),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, String symbol) {
    if (cardType == DetailCardType.income || cardType == DetailCardType.expense) {
      final transactions = ref.watch(transactionProvider);
      final targetType = cardType == DetailCardType.income ? TransactionType.income : TransactionType.expense;
      var filtered = transactions.where((t) => t.type == targetType).toList();

      if (dateRange != null) {
        final start = DateTime(dateRange!.start.year, dateRange!.start.month, dateRange!.start.day, 0, 0, 0);
        final end = DateTime(dateRange!.end.year, dateRange!.end.month, dateRange!.end.day, 23, 59, 59);
        filtered = filtered.where((t) =>
            (t.date.isAfter(start) || t.date.isAtSameMomentAs(start)) &&
            (t.date.isBefore(end) || t.date.isAtSameMomentAs(end))).toList();
      }

      if (filtered.isEmpty) {
        return const Center(child: Text('No transaction records found.'));
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filtered.length,
        itemBuilder: (ctx, idx) {
          final t = filtered[idx];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: targetType == TransactionType.income ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                targetType == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
                color: targetType == TransactionType.income ? Colors.green : Colors.red,
              ),
            ),
            title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${Formatters.date(t.date)} ${t.partyName != null ? '• ${t.partyName}' : ''}'),
            trailing: Text(
              '$symbol ${t.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: targetType == TransactionType.income ? Colors.green : Colors.red,
              ),
            ),
          );
        },
      );
    } else {
      final debts = ref.watch(debtProvider);
      final isReceivable = cardType == DetailCardType.receivables;
      final filtered = debts.where((d) => isReceivable ? !d.isOwedByMe : d.isOwedByMe).toList();

      if (filtered.isEmpty) {
        return Center(
          child: Text(isReceivable ? 'No receivables (money to collect).' : 'No payables (money due).'),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filtered.length,
        itemBuilder: (ctx, idx) {
          final d = filtered[idx];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isReceivable ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(isReceivable ? Icons.person_add : Icons.person_remove, color: isReceivable ? Colors.green : Colors.red),
            ),
            title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(isReceivable ? 'Borrower: ${d.partyName}' : 'Lender: ${d.partyName}'),
            trailing: Text(
              '$symbol ${d.currentBalance.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isReceivable ? Colors.green : Colors.red,
              ),
            ),
          );
        },
      );
    }
  }
}
