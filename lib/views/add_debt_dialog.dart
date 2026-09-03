import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../providers/firm_provider.dart';

class AddDebtDialog extends ConsumerStatefulWidget {
  const AddDebtDialog({super.key});

  @override
  ConsumerState<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends ConsumerState<AddDebtDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _partyController = TextEditingController();
  final _amountController = TextEditingController();
  final _aprController = TextEditingController(text: '18.5');
  final _minPaymentController = TextEditingController(text: '35.0');
  bool _isOwedByMe = true;

  @override
  void dispose() {
    _titleController.dispose();
    _partyController.dispose();
    _amountController.dispose();
    _aprController.dispose();
    _minPaymentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final apr = double.parse(_aprController.text);
      final minPayment = double.parse(_minPaymentController.text);

      final debt = DebtModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        partyName: _partyController.text.trim(),
        isOwedByMe: _isOwedByMe,
        originalAmount: amount,
        currentBalance: amount,
        apr: apr,
        minMonthlyPayment: minPayment,
        dueDate: DateTime.now().add(const Duration(days: 30)),
      );

      ref.read(debtProvider.notifier).addDebt(debt);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final firm = ref.watch(firmProvider);
    final symbol = firm.currencySymbol;

    return AlertDialog(
      title: const Text('Add Debt / Loan'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('I Owe (Liability)')),
                  ButtonSegment(value: false, label: Text('Owed to Me (Asset)')),
                ],
                selected: {_isOwedByMe},
                onSelectionChanged: (val) => setState(() => _isOwedByMe = val.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Debt Name (e.g., Credit Card)', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _partyController,
                decoration: const InputDecoration(labelText: 'Lender / Institution Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter party name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Initial Balance ($symbol)', border: const OutlineInputBorder()),
                validator: (val) {
                  final p = val == null ? null : double.tryParse(val);
                  return p == null || p <= 0 ? 'Enter balance greater than 0' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aprController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Interest Rate (APR %)', border: OutlineInputBorder()),
                validator: (val) {
                  final p = val == null ? null : double.tryParse(val);
                  return p == null || p < 0 ? 'Enter valid APR (0 or higher)' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minPaymentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Min Monthly Payment ($symbol)', border: const OutlineInputBorder()),
                validator: (val) {
                  final p = val == null ? null : double.tryParse(val);
                  return p == null || p < 0 ? 'Enter min payment (0 or higher)' : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF064E3B),
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: const Text('Save Debt'),
        ),
      ],
    );
  }
}
