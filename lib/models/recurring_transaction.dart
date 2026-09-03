import 'transaction.dart';

enum RecurringFrequency { daily, weekly, monthly, yearly }

class RecurringTransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final PaymentMethod paymentMethod;
  final String? partyName;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime nextDueDate;
  final DateTime? lastExecutedDate;
  final bool isActive;
  final String? notes;

  RecurringTransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.paymentMethod = PaymentMethod.cash,
    this.partyName,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    this.lastExecutedDate,
    this.isActive = true,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'paymentMethod': paymentMethod.name,
      'partyName': partyName,
      'frequency': frequency.name,
      'startDate': startDate.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'lastExecutedDate': lastExecutedDate?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'notes': notes,
    };
  }

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map) {
    return RecurringTransactionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      categoryId: map['categoryId'] as String,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      partyName: map['partyName'] as String?,
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      startDate: DateTime.parse(map['startDate'] as String),
      nextDueDate: DateTime.parse(map['nextDueDate'] as String),
      lastExecutedDate: map['lastExecutedDate'] != null
          ? DateTime.parse(map['lastExecutedDate'] as String)
          : null,
      isActive: (map['isActive'] as int) == 1,
      notes: map['notes'] as String?,
    );
  }

  RecurringTransactionModel copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    PaymentMethod? paymentMethod,
    String? partyName,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? nextDueDate,
    DateTime? lastExecutedDate,
    bool? isActive,
    String? notes,
  }) {
    return RecurringTransactionModel(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      partyName: partyName ?? this.partyName,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastExecutedDate: lastExecutedDate ?? this.lastExecutedDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }

  DateTime calculateNextDate(DateTime fromDate) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return fromDate.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return fromDate.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        int newYear = fromDate.year;
        int newMonth = fromDate.month + 1;
        if (newMonth > 12) {
          newYear += 1;
          newMonth = 1;
        }
        int newDay = fromDate.day;
        final daysInMonth = DateTime(newYear, newMonth + 1, 0).day;
        if (newDay > daysInMonth) newDay = daysInMonth;
        return DateTime(newYear, newMonth, newDay, fromDate.hour, fromDate.minute);
      case RecurringFrequency.yearly:
        return DateTime(fromDate.year + 1, fromDate.month, fromDate.day, fromDate.hour, fromDate.minute);
    }
  }
}
