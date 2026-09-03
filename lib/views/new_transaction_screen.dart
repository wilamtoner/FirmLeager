import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/debt.dart';
import '../models/category.dart';
import '../providers/transaction_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/category_provider.dart';

class NewTransactionScreen extends ConsumerStatefulWidget {
  final TransactionType initialType;

  const NewTransactionScreen({
    super.key,
    this.initialType = TransactionType.income,
  });

  @override
  ConsumerState<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends ConsumerState<NewTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TransactionType _transactionType;
  IncomeType _incomeType = IncomeType.goods;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _selectedCategoryId;

  final _titleController = TextEditingController();
  final _partyController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  static const Color darkGreen = Color(0xFF064E3B);

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initialType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _partyController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final categories = ref.read(categoryProvider);
      final partyName = _partyController.text.trim();

      String categoryId;
      if (_transactionType == TransactionType.income) {
        final incomeCat = categories.firstWhere(
          (c) => c.name.toLowerCase().contains('income'),
          orElse: () => categories.isNotEmpty ? categories.first : CategoryModel(id: 'cat_income', name: 'Salary & Income', colorHex: 0xFF009688),
        );
        categoryId = incomeCat.id;
      } else {
        categoryId = _selectedCategoryId ??
            (categories.where((c) => !c.name.toLowerCase().contains('income')).firstOrNull?.id ??
                (categories.isNotEmpty ? categories.first.id : 'cat_utilities'));
      }

      final transaction = TransactionModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        amount: amount,
        type: _transactionType,
        incomeType: _incomeType,
        paymentMethod: _paymentMethod,
        partyName: partyName.isEmpty ? null : partyName,
        categoryId: categoryId,
        date: _selectedDate,
      );

      // Save Transaction
      ref.read(transactionProvider.notifier).addTransaction(transaction);

      // Auto-create Debt entry if Payment Method is Credit
      if (_paymentMethod == PaymentMethod.credit && partyName.isNotEmpty) {
        final isReceivable = (_transactionType == TransactionType.income);
        final debt = DebtModel(
          id: const Uuid().v4(),
          title: '${_titleController.text.trim()} (Credit)',
          partyName: partyName,
          isOwedByMe: !isReceivable,
          originalAmount: amount,
          currentBalance: amount,
          apr: 0.0,
          minMonthlyPayment: amount,
          dueDate: _selectedDate.add(const Duration(days: 30)),
          notes: 'Auto-created from ${_transactionType.name} credit transaction',
        );
        ref.read(debtProvider.notifier).addDebt(debt);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_transactionType == TransactionType.income ? 'Income' : 'Expense'} entry saved!')),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = (_transactionType == TransactionType.income);
    final dateFormat = DateFormat('yyyy-MM-dd');
    final hasInput = _titleController.text.trim().isNotEmpty || _amountController.text.trim().isNotEmpty;

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
        if (shouldPop == true) {
          navigator.pop(result);
        }
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            isIncome ? 'New Income Entry' : 'New Expense Entry',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: darkGreen,
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
                // Entry Type Segmented Switcher
                Center(
                  child: SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('New Income'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('New Expense'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                    ],
                    selected: {_transactionType},
                    onSelectionChanged: (val) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() => _transactionType = val.first);
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Category / Income Type Dropdown
                Text(
                  isIncome ? 'Income Type*' : 'Expense Type*',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<IncomeType>(
                  key: ValueKey('type_dropdown_${_transactionType.name}'),
                  isExpanded: true,
                  isDense: true,
                  initialValue: _incomeType,
                  decoration: InputDecoration(
                    hintText: 'Select...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: isIncome
                      ? const [
                          DropdownMenuItem(value: IncomeType.goods, child: Text('Goods / Product Sales', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: IncomeType.service, child: Text('Service Revenue', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: IncomeType.other, child: Text('Other Income', overflow: TextOverflow.ellipsis)),
                        ]
                      : const [
                          DropdownMenuItem(value: IncomeType.goods, child: Text('Inventory / Goods Purchase', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: IncomeType.service, child: Text('Service / Subcontractor', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: IncomeType.other, child: Text('Operating Expense / Utilities', overflow: TextOverflow.ellipsis)),
                        ],
                  onChanged: (val) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (val != null) setState(() => _incomeType = val);
                  },
                ),
                const SizedBox(height: 16),

                if (!isIncome) ...[
                  const Text(
                    'Expense Category*',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('expense_category_dropdown'),
                    isExpanded: true,
                    isDense: true,
                    initialValue: _selectedCategoryId ??
                        (ref.watch(categoryProvider).where((c) => !c.name.toLowerCase().contains('income')).firstOrNull?.id),
                    decoration: InputDecoration(
                      hintText: 'Select Category...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: ref
                        .watch(categoryProvider)
                        .where((c) => !c.name.toLowerCase().contains('income'))
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (val) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (val != null) setState(() => _selectedCategoryId = val);
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Product or Service Name Input
                const Text(
                  'Product or Service Name*',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: InputDecoration(
                    hintText: isIncome ? 'e.g. Grain Supply / Software License' : 'e.g. Office Rent / Raw Materials',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter product or service name' : null,
                ),
                const SizedBox(height: 16),

                // Payment Method Dropdown (isExpanded: true + isDense: true + concise items!)
                const Text(
                  'Payment Method*',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<PaymentMethod>(
                  isExpanded: true,
                  isDense: true,
                  initialValue: _paymentMethod,
                  decoration: InputDecoration(
                    hintText: 'Select...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: PaymentMethod.bank, child: Text('Bank Transfer', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: PaymentMethod.cash, child: Text('Cash', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: PaymentMethod.credit, child: Text('Credit / On Account', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (val != null) setState(() => _paymentMethod = val);
                  },
                ),
                const SizedBox(height: 16),

                // Customer / Borrower or Supplier Name Input
                Text(
                  isIncome ? 'Customer / Borrower Name*' : 'Supplier / Vendor Name*',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _partyController,
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: InputDecoration(
                    hintText: isIncome ? 'e.g. Ram Traders' : 'e.g. Himalayan Wholesale',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (val) {
                    if (_paymentMethod == PaymentMethod.credit && (val == null || val.trim().isEmpty)) {
                      return 'Party name is required for credit transactions';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Amount Input
                const Text(
                  'Amount*',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: InputDecoration(
                    hintText: 'e.g. 5000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter amount';
                    final parsed = double.tryParse(val);
                    if (parsed == null || parsed <= 0) return 'Enter a valid amount greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker Input
                const Text(
                  'Date*',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _selectDate,
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
                            dateFormat.format(_selectedDate),
                            style: const TextStyle(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.calendar_month, color: darkGreen),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submit,
                    child: const Text(
                      'Submit',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
