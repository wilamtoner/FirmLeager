import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../providers/firm_provider.dart';
import '../theme/app_colors.dart';

class NewDebtScreen extends ConsumerStatefulWidget {
  final bool initialIsOwedByMe;

  const NewDebtScreen({
    super.key,
    this.initialIsOwedByMe = true,
  });

  @override
  ConsumerState<NewDebtScreen> createState() => _NewDebtScreenState();
}

class _NewDebtScreenState extends ConsumerState<NewDebtScreen> {
  final _formKey = GlobalKey<FormState>();

  late bool _isOwedByMe;
  final _titleController = TextEditingController();
  final _partyController = TextEditingController();
  final _amountController = TextEditingController();
  final _aprController = TextEditingController(text: '18.5');
  final _minPaymentController = TextEditingController(text: '35.0');
  final _notesController = TextEditingController();

  bool _noInterest = false;
  bool _noMonthlyPayment = false;
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 30));

  static const Color brandDark = AppColors.primaryDark;
  static const Color brandBlue = AppColors.primaryBlue;
  static const Color darkGreen = brandBlue;

  @override
  void initState() {
    super.initState();
    _isOwedByMe = widget.initialIsOwedByMe;
    if (!_isOwedByMe) {
      _noInterest = true;
      _noMonthlyPayment = true;
      _aprController.text = '0.0';
      _minPaymentController.text = '0.0';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _partyController.dispose();
    _amountController.dispose();
    _aprController.dispose();
    _minPaymentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2045),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDueDate = picked);
    }
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
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
        dueDate: _selectedDueDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      ref.read(debtProvider.notifier).addDebt(debt);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isOwedByMe ? 'Liability record saved!' : 'Asset record saved!'),
        ),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final firm = ref.watch(firmProvider);
    final symbol = firm.currencySymbol;
    final dateFormat = DateFormat('yyyy-MM-dd');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasInput = _titleController.text.trim().isNotEmpty ||
        _partyController.text.trim().isNotEmpty ||
        _amountController.text.trim().isNotEmpty;

    return PopScope(
      canPop: !hasInput,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard Entry?'),
            content: const Text('You have unsaved details that will be lost.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Editing')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Discard', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) {
          navigator.pop(result);
        }
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: Text(
              _isOwedByMe ? 'New Liability (I Owe)' : 'New Asset (Owed to Me)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: brandDark,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Segmented Switcher (Liability vs Asset)
                  Center(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('I Owe (Liability)'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Owed to Me (Asset)'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                      ],
                      selected: {_isOwedByMe},
                      onSelectionChanged: (val) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() {
                          _isOwedByMe = val.first;
                          if (!_isOwedByMe) {
                            _noInterest = true;
                            _noMonthlyPayment = true;
                            _aprController.text = '0.0';
                            _minPaymentController.text = '0.0';
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Debt Title
                  const Text(
                    'Debt / Loan Title*',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    decoration: InputDecoration(
                      hintText: _isOwedByMe
                          ? 'e.g. Bank Business Loan, Credit Card'
                          : 'e.g. Money Lent to Shyam, Advance Credit',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter title' : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. Counterparty Name
                  Text(
                    _isOwedByMe ? 'Lender / Creditor Name*' : 'Borrower / Debtor Name*',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _partyController,
                    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    decoration: InputDecoration(
                      hintText: _isOwedByMe ? 'e.g. Nabil Bank, Supplier ABC' : 'e.g. Ram Traders, Friend',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter party name' : null,
                  ),
                  const SizedBox(height: 16),

                  // 4. Principal Amount
                  Text(
                    'Principal Amount ($symbol)*',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    decoration: InputDecoration(
                      hintText: 'e.g. 50000',
                      prefixText: '$symbol ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter amount';
                      final parsed = double.tryParse(val.replaceAll(',', '.').trim());
                      if (parsed == null || parsed <= 0) return 'Enter a valid amount greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 5. Maturity / Due Date Picker
                  const Text(
                    'Maturity / Due Date*',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _selectDueDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              dateFormat.format(_selectedDueDate),
                              style: const TextStyle(fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.calendar_month, color: darkGreen),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. Interest Terms Card
                  Material(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Interest-Free (0% APR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    SizedBox(height: 2),
                                    Text('No interest or finance charges apply', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _noInterest,
                                activeThumbColor: darkGreen,
                                activeTrackColor: darkGreen.withValues(alpha: 0.5),
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
                            ],
                          ),
                          if (!_noInterest) ...[
                            const SizedBox(height: 12),
                            const Text('Annual Percentage Rate (APR %)*', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _aprController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                              decoration: InputDecoration(
                                hintText: '18.5',
                                suffixText: '%',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (val) {
                                if (_noInterest) return null;
                                if (val == null || val.trim().isEmpty) return 'Enter APR';
                                final p = double.tryParse(val.replaceAll(',', '.').trim());
                                return p == null || p < 0 ? 'Enter valid APR percentage' : null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 7. Repayment Terms Card
                  Material(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Flexible Repayment (No Fixed Monthly)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    SizedBox(height: 2),
                                    Text('Pay back on demand or in lump sum at maturity', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _noMonthlyPayment,
                                activeThumbColor: darkGreen,
                                activeTrackColor: darkGreen.withValues(alpha: 0.5),
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
                            ],
                          ),
                          if (!_noMonthlyPayment) ...[
                            const SizedBox(height: 8),
                            Text('Minimum Monthly Payment ($symbol)*', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _minPaymentController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                              decoration: InputDecoration(
                                hintText: '35.0',
                                prefixText: '$symbol ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (val) {
                                if (_noMonthlyPayment) return null;
                                if (val == null || val.trim().isEmpty) return 'Enter monthly payment';
                                final p = double.tryParse(val.replaceAll(',', '.').trim());
                                return p == null || p < 0 ? 'Enter valid payment amount' : null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 8. Notes / Remarks
                  const Text(
                    'Notes / Reference (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    decoration: InputDecoration(
                      hintText: 'Optional collateral, agreement notes, or loan reference ID',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 9. Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submit,
                      icon: const Icon(Icons.check, size: 20),
                      label: Text(
                        _isOwedByMe ? 'Save Liability Record' : 'Save Asset Record',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
