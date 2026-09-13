import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/firm_provider.dart';
import '../theme/app_colors.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  const AddTransactionDialog({super.key});

  @override
  ConsumerState<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _selectedCategoryId;
  final DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final sanitizedText = _amountController.text.replaceAll(',', '.').trim();
      final amount = double.tryParse(sanitizedText) ?? 0.0;
      if (amount <= 0) return;
      final categories = ref.read(categoryProvider);

      String categoryId = _selectedCategoryId ??
          (_type == TransactionType.income
              ? (categories.where((c) => c.name.toLowerCase().contains('income')).firstOrNull?.id ??
                  (categories.isNotEmpty ? categories.first.id : 'cat_income'))
              : (categories.isNotEmpty ? categories.first.id : 'cat_general'));

      final transaction = TransactionModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        categoryId: categoryId,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      ref.read(transactionProvider.notifier).addTransaction(transaction);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final firm = ref.watch(firmProvider);
    final symbol = firm.currencySymbol;

    return AlertDialog(
      title: const Text('Add Transaction'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.remove_circle_outline)),
                  ButtonSegment(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.add_circle_outline)),
                ],
                selected: {_type},
                onSelectionChanged: (val) {
                  setState(() {
                    _type = val.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title / Item', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Amount ($symbol)', border: const OutlineInputBorder()),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter an amount';
                  final parsed = double.tryParse(val.replaceAll(',', '.').trim());
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId ?? (categories.isNotEmpty ? categories.first.id : null),
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
