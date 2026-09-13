import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../providers/firm_provider.dart';
import '../theme/app_colors.dart';

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
  bool _noInterest = false;
  bool _noMonthlyPayment = false;

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
      final sanitizedAmount = _amountController.text.replaceAll(',', '.').trim();
      final amount = double.tryParse(sanitizedAmount) ?? 0.0;
      if (amount <= 0) return;
      final apr = _noInterest
          ? 0.0
          : (double.tryParse(_aprController.text.replaceAll(',', '.').trim()) ?? 0.0);
      final minPayment = _noMonthlyPayment
          ? 0.0
          : (double.tryParse(_minPaymentController.text.replaceAll(',', '.').trim()) ?? 0.0);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('I Owe (Liability)')),
                  ButtonSegment(value: false, label: Text('Owed to Me (Asset)')),
                ],
                selected: {_isOwedByMe},
                onSelectionChanged: (val) {
                  setState(() {
                    _isOwedByMe = val.first;
                    // Auto-suggest 0% interest and flexible payment for money lent out
                    if (!_isOwedByMe) {
                      _noInterest = true;
                      _noMonthlyPayment = true;
                      _aprController.text = '0.0';
                      _minPaymentController.text = '0.0';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Debt Name (e.g., Credit Card, Friend Loan)', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _partyController,
                decoration: InputDecoration(
                  labelText: _isOwedByMe ? 'Lender / Institution Name' : 'Borrower Name',
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter party name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Initial Balance ($symbol)', border: const OutlineInputBorder()),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter balance';
                  final p = double.tryParse(val.replaceAll(',', '.').trim());
                  return p == null || p <= 0 ? 'Enter balance greater than 0' : null;
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 4),

              // 1. No Interest (0% APR) Toggle
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('No Interest (0% APR)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Interest-free loan without any finance charges', style: TextStyle(fontSize: 12)),
                value: _noInterest,
                activeThumbColor: AppColors.primaryBlue,
                onChanged: (val) {
                  setState(() {
                    _noInterest = val;
                    if (val) {
                      _aprController.text = '0.0';
                    } else if (_aprController.text == '0.0' || _aprController.text == '0') {
                      _aprController.text = '18.5';
                    }
                  });
                },
              ),
              if (_noInterest)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '0% APR — Interest-free debt',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _aprController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Interest Rate (APR %)', border: OutlineInputBorder()),
                    validator: (val) {
                      if (_noInterest) return null;
                      if (val == null || val.trim().isEmpty) return 'Enter valid APR (0 or higher)';
                      final p = double.tryParse(val.replaceAll(',', '.').trim());
                      return p == null || p < 0 ? 'Enter valid APR (0 or higher)' : null;
                    },
                  ),
                ),

              // 2. No Monthly Payment Option
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('No Monthly Payment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Flexible payoff — pay anytime or lump-sum', style: TextStyle(fontSize: 12)),
                value: _noMonthlyPayment,
                activeThumbColor: AppColors.primaryBlue,
                onChanged: (val) {
                  setState(() {
                    _noMonthlyPayment = val;
                    if (val) {
                      _minPaymentController.text = '0.0';
                    } else if (_minPaymentController.text == '0.0' || _minPaymentController.text == '0') {
                      _minPaymentController.text = '35.0';
                    }
                  });
                },
              ),
              if (_noMonthlyPayment)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.schedule_outlined, color: Colors.teal, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Flexible Payoff — No fixed monthly installment',
                          style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    controller: _minPaymentController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Min Monthly Payment ($symbol)', border: const OutlineInputBorder()),
                    validator: (val) {
                      if (_noMonthlyPayment) return null;
                      if (val == null || val.trim().isEmpty) return 'Enter min payment (0 or higher)';
                      final p = double.tryParse(val.replaceAll(',', '.').trim());
                      return p == null || p < 0 ? 'Enter min payment (0 or higher)' : null;
                    },
                  ),
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
          child: const Text('Save Debt'),
        ),
      ],
    );
  }
}
