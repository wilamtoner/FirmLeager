import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/firm_profile.dart';

class CsvExporter {
  static Future<File> generateTransactionCsv({
    required List<TransactionModel> transactions,
    required FirmProfileModel firm,
    required DateTimeRange dateRange,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('FIRM STATEMENT REPORT');
    buffer.writeln('Firm Name,${firm.name}');
    buffer.writeln('Tax ID,${firm.taxId}');
    buffer.writeln('Period,${dateFormat.format(dateRange.start)} to ${dateFormat.format(dateRange.end)}');
    buffer.writeln('');

    buffer.writeln('Transaction ID,Date,Type,Category/Item,Party Name,Payment Method,Amount (${firm.currencySymbol})');

    final start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day, 0, 0, 0);
    final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);

    final filtered = transactions.where((t) =>
        (t.date.isAfter(start) || t.date.isAtSameMomentAs(start)) &&
        (t.date.isBefore(end) || t.date.isAtSameMomentAs(end))).toList();

    for (var t in filtered) {
      final dateStr = dateFormat.format(t.date);
      final typeStr = t.type.name.toUpperCase();
      final titleStr = '"${t.title.replaceAll('"', '""')}"';
      final partyStr = '"${(t.partyName ?? '-').replaceAll('"', '""')}"';
      final methodStr = t.paymentMethod.name.toUpperCase();
      final amountStr = t.amount.toStringAsFixed(2);

      buffer.writeln('${t.id},$dateStr,$typeStr,$titleStr,$partyStr,$methodStr,$amountStr');
    }

    final directory = Directory.systemTemp;
    final path = '${directory.path}/firm_statement_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    return await file.writeAsString(buffer.toString());
  }
}
