class DebtModel {
  final String id;
  final String title;
  final String partyName; // Lender or Borrower
  final bool isOwedByMe; // true = I owe money (liability), false = Owed to me (asset)
  final double originalAmount;
  final double currentBalance;
  final double apr; // Interest rate %
  final double minMonthlyPayment;
  final DateTime dueDate;
  final String? notes;

  DebtModel({
    required this.id,
    required this.title,
    required this.partyName,
    required this.isOwedByMe,
    required this.originalAmount,
    required this.currentBalance,
    required this.apr,
    required this.minMonthlyPayment,
    required this.dueDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'partyName': partyName,
      'isOwedByMe': isOwedByMe ? 1 : 0,
      'originalAmount': originalAmount,
      'currentBalance': currentBalance,
      'apr': apr,
      'minMonthlyPayment': minMonthlyPayment,
      'dueDate': dueDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as String,
      title: map['title'] as String,
      partyName: map['partyName'] as String,
      isOwedByMe: (map['isOwedByMe'] as int) == 1,
      originalAmount: (map['originalAmount'] as num).toDouble(),
      currentBalance: (map['currentBalance'] as num).toDouble(),
      apr: (map['apr'] as num).toDouble(),
      minMonthlyPayment: (map['minMonthlyPayment'] as num).toDouble(),
      dueDate: DateTime.parse(map['dueDate'] as String),
      notes: map['notes'] as String?,
    );
  }

  DebtModel copyWith({
    double? currentBalance,
  }) {
    return DebtModel(
      id: id,
      title: title,
      partyName: partyName,
      isOwedByMe: isOwedByMe,
      originalAmount: originalAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      apr: apr,
      minMonthlyPayment: minMonthlyPayment,
      dueDate: dueDate,
      notes: notes,
    );
  }
}
