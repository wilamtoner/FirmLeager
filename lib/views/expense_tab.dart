import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/firm_provider.dart';
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
          const SizedBox(height: 8),

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
    Color bg;
    String label;
    switch (method) {
      case PaymentMethod.bank:
        bg = Colors.blue.shade100;
        label = 'Bank';
        break;
      case PaymentMethod.cash:
        bg = Colors.green.shade100;
        label = 'Cash';
        break;
      case PaymentMethod.credit:
        bg = Colors.amber.shade100;
        label = 'Credit';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
