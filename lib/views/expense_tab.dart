import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/firm_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/formatters.dart';
import 'new_transaction_screen.dart';

class ExpenseTab extends ConsumerStatefulWidget {
  const ExpenseTab({super.key});

  @override
  ConsumerState<ExpenseTab> createState() => _ExpenseTabState();
}

class _ExpenseTabState extends ConsumerState<ExpenseTab> {
  String _searchQuery = '';
  String _filterType = 'all';

  static const Color darkGreen = Color(0xFF064E3B);

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final categories = ref.watch(categoryProvider);
    final firm = ref.watch(firmProvider);
    final budgetStatuses = ref.watch(categoryBudgetProvider);

    final filtered = transactions.where((t) {
      final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.partyName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesFilter = true;
      if (_filterType == 'income') matchesFilter = (t.type == TransactionType.income);
      if (_filterType == 'expense') matchesFilter = (t.type == TransactionType.expense);
      if (_filterType == 'credit') matchesFilter = (t.paymentMethod == PaymentMethod.credit);
      if (_filterType == 'cash') matchesFilter = (t.paymentMethod == PaymentMethod.cash);

      return matchesSearch && matchesFilter;
    }).toList();

    final categoryMap = {for (var c in categories) c.id: c};

    return Scaffold(
      body: Column(
        children: [
          // Search Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions or party names...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Interactive Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Entries (${transactions.length})'),
                const SizedBox(width: 6),
                _buildFilterChip('income', 'Income 🟢'),
                const SizedBox(width: 6),
                _buildFilterChip('expense', 'Expense 🔴'),
                const SizedBox(width: 6),
                _buildFilterChip('credit', 'Credit 💳'),
                const SizedBox(width: 6),
                _buildFilterChip('cash', 'Cash 💵'),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Monthly Category Budgets & Alerts
          if (budgetStatuses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Card(
                elevation: 0,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: budgetStatuses.any((b) => b.isOverBudget)
                        ? Colors.red.shade400
                        : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : Colors.grey.shade300),
                    width: budgetStatuses.any((b) => b.isOverBudget) ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: budgetStatuses.any((b) => b.isNearBudget || b.isOverBudget),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    leading: Icon(
                      budgetStatuses.any((b) => b.isOverBudget)
                          ? Icons.warning_amber_rounded
                          : Icons.account_balance_wallet_outlined,
                      size: 20,
                      color: budgetStatuses.any((b) => b.isOverBudget) ? Colors.red : darkGreen,
                    ),
                    title: Row(
                      children: [
                        const Text(
                          'Category Budgets',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Spacer(),
                        if (budgetStatuses.any((b) => b.isOverBudget))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${budgetStatuses.where((b) => b.isOverBudget).length} Over Budget!',
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                        child: Column(
                          children: budgetStatuses
                              .map((b) => _buildBudgetProgressRow(b, firm.currencySymbol))
                              .toList(),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),

          // Transaction List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No transactions match your filter.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final t = filtered[idx];
                      final cat = categoryMap[t.categoryId] ??
                          CategoryModel(id: 'other', name: 'General', colorHex: 0xFF9E9E9E);

                      return Dismissible(
                        key: Key(t.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          ref.read(transactionProvider.notifier).deleteTransaction(t.id);
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: t.type == TransactionType.income ? darkGreen : Colors.redAccent,
                              child: Icon(
                                t.type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${cat.name} • ${Formatters.date(t.date)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                _buildMethodBadge(t.paymentMethod),
                              ],
                            ),
                            trailing: Text(
                              '${t.type == TransactionType.income ? '+' : '-'}${firm.currencySymbol} ${t.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: t.type == TransactionType.income ? darkGreen : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const NewTransactionScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = (_filterType == value);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: darkGreen.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? darkGreen : Colors.grey.shade700,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _filterType = value);
      },
    );
  }

  Widget _buildMethodBadge(PaymentMethod method) {
    final (bg, label) = switch (method) {
      PaymentMethod.bank => (Colors.blue.shade100, 'Bank'),
      PaymentMethod.cash => (Colors.green.shade100, 'Cash'),
      PaymentMethod.credit => (Colors.amber.shade100, 'Credit'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBudgetProgressRow(CategoryBudgetStatus b, String symbol) {
    Color progressColor;
    if (b.isOverBudget) {
      progressColor = Colors.red;
    } else if (b.isNearBudget) {
      progressColor = Colors.amber.shade700;
    } else {
      progressColor = darkGreen;
    }

    final double clampedProgress = (b.percentage / 100.0).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(b.category.colorHex),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    b.category.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                '$symbol${b.spentAmount.toStringAsFixed(0)} / $symbol${b.budgetLimit.toStringAsFixed(0)} (${b.percentage.toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: b.isOverBudget ? Colors.red : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clampedProgress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
