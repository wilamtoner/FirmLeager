import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction.dart';
import '../models/firm_profile.dart';

class PdfInvoiceGenerator {
  static String sanitizeText(String text) {
    final clean = text
        .replaceAll('€', 'EUR ')
        .replaceAll('£', 'GBP ')
        .replaceAll('₹', 'Rs. ')
        .replaceAll(RegExp(r'[^\x20-\x7E\r\n\t]'), ' ')
        .trim();
    return clean.isEmpty ? '-' : clean;
  }

  static String sanitizeCurrency(String symbol) {
    if (symbol == '€') return 'EUR';
    if (symbol == '£') return 'GBP';
    if (symbol == '₹') return 'Rs.';
    final clean = symbol.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
    return clean.isEmpty ? 'Rs.' : clean;
  }

  static pw.Document buildStatementDocument({
    required List<TransactionModel> transactions,
    required FirmProfileModel firm,
    required DateTimeRange dateRange,
  }) {
    final doc = pw.Document();

    final dateFormat = DateFormat('yyyy-MM-dd');
    final startDateStr = dateFormat.format(dateRange.start);
    final endDateStr = dateFormat.format(dateRange.end);

    // Strictly filter transactions by date range
    final start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day, 0, 0, 0);
    final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);

    final filtered = transactions.where((t) =>
        (t.date.isAfter(start) || t.date.isAtSameMomentAs(start)) &&
        (t.date.isBefore(end) || t.date.isAtSameMomentAs(end))).toList();

    // Compute Totals
    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in filtered) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }
    final netBalance = totalIncome - totalExpense;

    final primaryGreen = PdfColor.fromHex('#0A2540'); // Brand Navy Header
    final secondaryMint = PdfColor.fromHex('#0D6EFD'); // Brand Royal Blue Accent
    final tableHeaderBg = PdfColor.fromHex('#0A2540');
    final rowAltBg = PdfColor.fromHex('#F8FAFC');

    final safeCurrency = sanitizeCurrency(firm.currencySymbol);
    final safeFirmName = sanitizeText(firm.name).toUpperCase();
    final safeTaxId = sanitizeText(firm.taxId);
    final safeAddress = sanitizeText(firm.address);
    final safePhone = sanitizeText(firm.phone);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => [
          // Header Section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    safeFirmName.isEmpty ? 'DEMO FIRM PVT. LTD.' : safeFirmName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Tax ID / PAN: $safeTaxId', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text('Address: $safeAddress', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text('Phone: $safePhone', style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: primaryGreen,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'FINANCIAL STATEMENT',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text('Period: $startDateStr to $endDateStr', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Generated: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
          pw.Divider(color: primaryGreen, thickness: 1.5, height: 24),

          // Executive Financial Summary KPI Cards
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#ECFDF5'),
                    border: pw.Border.all(color: secondaryMint, width: 1),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total Inflow', style: pw.TextStyle(fontSize: 10, color: primaryGreen, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '$safeCurrency ${totalIncome.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryGreen),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FEF2F2'),
                    border: pw.Border.all(color: PdfColor.fromHex('#EF4444'), width: 1),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total Outflow', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#991B1B'), fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '$safeCurrency ${totalExpense.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#991B1B')),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F0FDF4'),
                    border: pw.Border.all(color: primaryGreen, width: 1),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Net Balance', style: pw.TextStyle(fontSize: 10, color: primaryGreen, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '$safeCurrency ${netBalance.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryGreen),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Transaction Breakdown Table
          pw.Text('Transaction Details (${filtered.length} entries)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          filtered.isEmpty
              ? pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 24),
                    child: pw.Text('No transactions recorded for this period.', style: const pw.TextStyle(color: PdfColors.grey600)),
                  ),
                )
              : pw.Table(
                  border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.5),
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: tableHeaderBg),
                      children: [
                        _buildTableHeaderCell('Date'),
                        _buildTableHeaderCell('Type'),
                        _buildTableHeaderCell('Item Description'),
                        _buildTableHeaderCell('Counterparty'),
                        _buildTableHeaderCell('Method'),
                        _buildTableHeaderCell('Amount ($safeCurrency)', align: pw.TextAlign.right),
                      ],
                    ),
                    // Table Rows
                    ...filtered.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final t = entry.value;
                      final isIncome = (t.type == TransactionType.income);
                      final isEven = (idx % 2 == 0);

                      return pw.TableRow(
                        decoration: isEven ? null : pw.BoxDecoration(color: rowAltBg),
                        children: [
                          _buildTableCell(dateFormat.format(t.date)),
                          _buildTableCell(isIncome ? 'INCOME' : 'EXPENSE', color: isIncome ? primaryGreen : PdfColor.fromHex('#DC2626'), bold: true),
                          _buildTableCell(sanitizeText(t.title)),
                          _buildTableCell(t.partyName != null && t.partyName!.isNotEmpty ? sanitizeText(t.partyName!) : '-'),
                          _buildTableCell(t.paymentMethod.name.toUpperCase()),
                          _buildTableCell(
                            '${isIncome ? '+' : '-'}${t.amount.toStringAsFixed(2)}',
                            color: isIncome ? primaryGreen : PdfColor.fromHex('#DC2626'),
                            bold: true,
                            align: pw.TextAlign.right,
                          ),
                        ],
                      );
                    }),
                  ],
                ),

          pw.SizedBox(height: 32),

          // Signatory & Stamp Block
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Generated by FirmLedger System', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  pw.Text('Offline-First Private Financial Accounting', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(
                    width: 160,
                    height: 1,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Authorized Signature & Stamp', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              )
            ],
          )
        ],
      ),
    );

    return doc;
  }

  static Future<void> exportAndPrintStatement({
    required BuildContext context,
    required List<TransactionModel> transactions,
    required FirmProfileModel firm,
    required DateTimeRange dateRange,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final startDateStr = dateFormat.format(dateRange.start);
    final endDateStr = dateFormat.format(dateRange.end);

    final doc = buildStatementDocument(
      transactions: transactions,
      firm: firm,
      dateRange: dateRange,
    );

    // Launch Printing / PDF Preview Dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'FirmLedger_Statement_${startDateStr}_$endDateStr.pdf',
    );
  }

  static pw.Widget _buildTableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    PdfColor? color,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8.5,
          color: color ?? PdfColors.black,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
