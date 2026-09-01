enum TransactionType { income, expense }
enum IncomeType { goods, service, other }
enum PaymentMethod { bank, cash, credit }

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final IncomeType incomeType;
  final PaymentMethod paymentMethod;
  final String? partyName; // Customer or Supplier Name
  final String categoryId;
  final DateTime date;
  final String? notes;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.incomeType = IncomeType.goods,
    this.paymentMethod = PaymentMethod.cash,
    this.partyName,
    required this.categoryId,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'incomeType': incomeType.name,
      'paymentMethod': paymentMethod.name,
      'partyName': partyName,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      incomeType: IncomeType.values.firstWhere((e) => e.name == map['incomeType'], orElse: () => IncomeType.goods),
      paymentMethod: PaymentMethod.values.firstWhere((e) => e.name == map['paymentMethod'], orElse: () => PaymentMethod.cash),
      partyName: map['partyName'] as String?,
      categoryId: map['categoryId'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    );
  }
}
