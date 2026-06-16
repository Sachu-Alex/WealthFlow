import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/expense.dart';
import '../models/investment.dart';
import '../models/withdrawal.dart';

/// PDF generation service.
///
/// Uses built-in Helvetica — no network calls, works fully offline.
/// Currency is formatted as "Rs." because Helvetica has no Unicode glyph for
/// the Indian Rupee sign (U+20B9).  Empty fields show "-" (ASCII hyphen)
/// instead of an em-dash for the same reason.
class PdfReportService {
  // ─── Brand colours ────────────────────────────────────────────────────────
  static final _green = PdfColor.fromHex('10B981');
  static final _greenLight = PdfColor.fromHex('D1FAE5');
  static final _dark = PdfColor.fromHex('1F2937');
  static final _teal = PdfColor.fromHex('0D9488');
  static final _slate = PdfColor.fromHex('64748B');
  static final _bgLight = PdfColor.fromHex('F8FAFC');
  static final _rowAlt = PdfColor.fromHex('F1F5F9');
  static final _red = PdfColor.fromHex('EF4444');
  static final _redLight = PdfColor.fromHex('FEE2E2');
  static final _border = PdfColor.fromHex('E2E8F0');

  // Use "Rs." — Helvetica has no glyph for U+20B9 (Indian Rupee sign)
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _currFmt =
      NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

  // ═══════════════════════════════════════════════════════════════════════════
  // Expense / Transaction report
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> generateReport({
    required String userName,
    required String userEmail,
    required List<Expense> expenses,
    required List<Withdrawal> withdrawals,
    DateTime? reportDate,
  }) async {
    final now = reportDate ?? DateTime.now();

    final sortedExp = [...expenses]
      ..sort((a, b) => b.date.compareTo(a.date));
    final sortedWith = [...withdrawals]
      ..sort((a, b) => b.withdrawalDate.compareTo(a.withdrawalDate));

    final totalExp = expenses.fold(0.0, (s, e) => s + e.amount);
    final totalWith = withdrawals.fold(0.0, (s, w) => s + w.amount);

    final monthStart = DateTime(now.year, now.month, 1);
    final monthExp = expenses
        .where((e) => !e.date.isBefore(monthStart))
        .fold(0.0, (s, e) => s + e.amount);

    final catTotals = <String, double>{};
    for (final e in expenses) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final doc = pw.Document(
      title: 'WealthFlow Transaction Report',
      author: userName,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        header: (ctx) => _txHeader(userName, userEmail, now),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 18),
          _summaryRow(
              totalExp, totalWith, monthExp, sortedExp.length, sortedWith.length),
          pw.SizedBox(height: 26),
          if (sortedExp.isNotEmpty) ...[
            _sectionTitle('Expense Transactions'),
            pw.SizedBox(height: 8),
            _expenseTable(sortedExp),
            pw.SizedBox(height: 26),
          ],
          if (sortedWith.isNotEmpty) ...[
            _sectionTitle('Investment Withdrawals'),
            pw.SizedBox(height: 8),
            _withdrawalTable(sortedWith),
            pw.SizedBox(height: 26),
          ],
          if (sortedCats.isNotEmpty) ...[
            _sectionTitle('Spending by Category'),
            pw.SizedBox(height: 8),
            _categoryTable(sortedCats, totalExp),
          ],
        ],
      ),
    );

    return doc.save();
  }

  // ─── Transaction report header ────────────────────────────────────────────

  static pw.Widget _txHeader(String name, String email, DateTime now) {
    return pw.Column(children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: pw.BoxDecoration(
          color: _dark,
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(children: [
                  pw.Container(
                    width: 10,
                    height: 10,
                    decoration: pw.BoxDecoration(
                      color: _green,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    'WealthFlow',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ]),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Transaction Report',
                  style: pw.TextStyle(fontSize: 10, color: _green),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(email,
                    style: pw.TextStyle(fontSize: 9, color: _slate)),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Generated: ${_dateFmt.format(now)}',
                  style: pw.TextStyle(fontSize: 9, color: _slate),
                ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 6),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Investment report
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> generateInvestmentReport({
    required Investment investment,
    required List<Withdrawal> withdrawals,
    DateTime? reportDate,
  }) async {
    final now = reportDate ?? DateTime.now();
    final sorted = [...withdrawals]
      ..sort((a, b) => b.withdrawalDate.compareTo(a.withdrawalDate));

    final totalWithdrawn = withdrawals.fold(0.0, (s, w) => s + w.amount);
    final remaining = investment.initialAmount - totalWithdrawn;
    final pct = investment.initialAmount > 0
        ? totalWithdrawn / investment.initialAmount * 100
        : 0.0;

    final monthly = <String, double>{};
    for (final w in withdrawals) {
      final key =
          '${w.withdrawalDate.year}-${w.withdrawalDate.month.toString().padLeft(2, '0')}';
      monthly[key] = (monthly[key] ?? 0) + w.amount;
    }
    final sortedMonthly = monthly.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    final doc = pw.Document(
      title: 'WealthFlow - ${investment.investorName} Investment Report',
      author: investment.investorName,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        header: (ctx) => _investmentHeader(investment, now),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 18),
          _investmentSummaryRow(
            investment.initialAmount,
            totalWithdrawn,
            remaining,
            pct,
            withdrawals.length,
          ),
          pw.SizedBox(height: 26),
          if (sorted.isNotEmpty) ...[
            _sectionTitle('Withdrawal History'),
            pw.SizedBox(height: 8),
            _withdrawalTable(sorted),
            pw.SizedBox(height: 26),
          ],
          if (sortedMonthly.isNotEmpty) ...[
            _sectionTitle('Monthly Breakdown'),
            pw.SizedBox(height: 8),
            _monthlyTable(sortedMonthly),
          ],
          if (investment.notes?.isNotEmpty == true) ...[
            pw.SizedBox(height: 26),
            _sectionTitle('Notes'),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _bgLight,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: _border, width: 0.5),
              ),
              child: pw.Text(
                investment.notes!,
                style: pw.TextStyle(fontSize: 9, color: _dark),
              ),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  // ─── Investment report header (solid teal — no gradient) ─────────────────

  static pw.Widget _investmentHeader(Investment investment, DateTime now) {
    return pw.Column(children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: pw.BoxDecoration(
          color: _teal,
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(children: [
                  pw.Container(
                    width: 10,
                    height: 10,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    'WealthFlow',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ]),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Investment Report',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  investment.investorName,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Since ${_dateFmt.format(investment.investmentDate)}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.white),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Generated: ${_dateFmt.format(now)}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.white),
                ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 6),
    ]);
  }

  static pw.Widget _investmentSummaryRow(
    double initial,
    double withdrawn,
    double remaining,
    double pct,
    int count,
  ) {
    final amber = PdfColor.fromHex('D97706');
    final amberLight = PdfColor.fromHex('FEF3C7');
    final emerald = PdfColor.fromHex('16A34A');
    final emeraldLight = PdfColor.fromHex('DCFCE7');

    return pw.Row(children: [
      _summaryCard('Initial Investment', _currFmt.format(initial),
          'Original corpus', _green, _greenLight),
      pw.SizedBox(width: 12),
      _summaryCard('Total Withdrawn', _currFmt.format(withdrawn),
          '$count withdrawals', amber, amberLight),
      pw.SizedBox(width: 12),
      _summaryCard('Remaining Balance', _currFmt.format(remaining),
          '${pct.toStringAsFixed(1)}% used', emerald, emeraldLight),
    ]);
  }

  // ─── Footer ───────────────────────────────────────────────────────────────

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.8)),
      ),
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'WealthFlow - Confidential',
            style: pw.TextStyle(color: _slate, fontSize: 8),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(color: _slate, fontSize: 8),
          ),
        ],
      ),
    );
  }

  // ─── Section title ────────────────────────────────────────────────────────

  static pw.Widget _sectionTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(children: [
          pw.Container(
            width: 4,
            height: 16,
            decoration: pw.BoxDecoration(
              color: _green,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _dark,
            ),
          ),
        ]),
        pw.SizedBox(height: 4),
        pw.Divider(color: _border, thickness: 0.8),
      ],
    );
  }

  // ─── Summary row ──────────────────────────────────────────────────────────

  static pw.Widget _summaryRow(
    double totalExp,
    double totalWith,
    double monthExp,
    int expCount,
    int withCount,
  ) {
    return pw.Row(children: [
      _summaryCard('Total Expenses', _currFmt.format(totalExp),
          '$expCount transactions', _green, _greenLight),
      pw.SizedBox(width: 12),
      _summaryCard('Total Withdrawals', _currFmt.format(totalWith),
          '$withCount entries', _red, _redLight),
      pw.SizedBox(width: 12),
      _summaryCard(
          'This Month', _currFmt.format(monthExp), 'Expenses', _dark, _bgLight),
    ]);
  }

  static pw.Widget _summaryCard(
    String title,
    String value,
    String sub,
    PdfColor accent,
    PdfColor bg,
  ) {
    // pdf package forbids borderRadius + non-uniform Border together.
    // Workaround: outer container = accent colour + full border-radius + 4 px
    // left padding (the visible accent strip). Inner container = bg colour,
    // no border, no radius — fills the rest.
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.only(left: 4),
        decoration: pw.BoxDecoration(
          color: accent,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Container(
          padding: const pw.EdgeInsets.all(14),
          color: bg,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 8, color: _slate)),
              pw.SizedBox(height: 5),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _dark,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(sub, style: pw.TextStyle(fontSize: 8, color: _slate)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Expense table ────────────────────────────────────────────────────────

  static pw.Widget _expenseTable(List<Expense> expenses) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FixedColumnWidth(82),
        2: const pw.FixedColumnWidth(88),
        3: const pw.FlexColumnWidth(),
        4: const pw.FixedColumnWidth(100),
      },
      children: [
        _headerRow(['#', 'Date', 'Category', 'Description', 'Amount']),
        ...expenses.asMap().entries.map((e) => _expenseRow(e.key, e.value)),
        _totalRow(
          4,
          _currFmt.format(expenses.fold(0.0, (s, e) => s + e.amount)),
          _green,
          _greenLight,
        ),
      ],
    );
  }

  static pw.TableRow _expenseRow(int idx, Expense e) {
    return pw.TableRow(
      decoration:
          pw.BoxDecoration(color: idx % 2 == 0 ? PdfColors.white : _rowAlt),
      children: [
        _cell('${idx + 1}', center: true),
        _cell(_dateFmt.format(e.date)),
        _cell(e.category),
        _cell(e.note?.isNotEmpty == true ? e.note! : '-'),
        _cell(_currFmt.format(e.amount), right: true),
      ],
    );
  }

  // ─── Withdrawal table ─────────────────────────────────────────────────────

  static pw.Widget _withdrawalTable(List<Withdrawal> withdrawals) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FixedColumnWidth(100),
        2: const pw.FlexColumnWidth(),
        3: const pw.FixedColumnWidth(110),
      },
      children: [
        _headerRow(['#', 'Date', 'Remarks', 'Amount']),
        ...withdrawals.asMap().entries.map((e) => _withdrawalRow(e.key, e.value)),
        _totalRow(
          3,
          _currFmt.format(withdrawals.fold(0.0, (s, w) => s + w.amount)),
          _red,
          _redLight,
        ),
      ],
    );
  }

  static pw.TableRow _withdrawalRow(int idx, Withdrawal w) {
    return pw.TableRow(
      decoration:
          pw.BoxDecoration(color: idx % 2 == 0 ? PdfColors.white : _rowAlt),
      children: [
        _cell('${idx + 1}', center: true),
        _cell(_dateFmt.format(w.withdrawalDate)),
        _cell(w.remarks?.isNotEmpty == true ? w.remarks! : '-'),
        _cell(_currFmt.format(w.amount), right: true),
      ],
    );
  }

  // ─── Category table ───────────────────────────────────────────────────────

  static pw.Widget _categoryTable(
      List<MapEntry<String, double>> cats, double total) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FixedColumnWidth(65),
      },
      children: [
        _headerRow(['Category', 'Amount', 'Share']),
        ...cats.asMap().entries.map((entry) {
          final idx = entry.key;
          final cat = entry.value;
          final pct = total > 0 ? cat.value / total * 100 : 0.0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: idx % 2 == 0 ? PdfColors.white : _rowAlt),
            children: [
              _cell(cat.key),
              _cell(_currFmt.format(cat.value), right: true),
              _cell('${pct.toStringAsFixed(1)}%', right: true),
            ],
          );
        }),
      ],
    );
  }

  // ─── Monthly table ────────────────────────────────────────────────────────

  static pw.Widget _monthlyTable(List<MapEntry<String, double>> months) {
    final monthFmt = DateFormat('MMM yyyy');
    final grandTotal = months.fold(0.0, (s, e) => s + e.value);
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(70),
      },
      children: [
        _headerRow(['#', 'Month', 'Amount', 'Share']),
        ...months.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;
          final pct = grandTotal > 0 ? m.value / grandTotal * 100 : 0.0;
          final parts = m.key.split('-');
          final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: idx % 2 == 0 ? PdfColors.white : _rowAlt),
            children: [
              _cell('${idx + 1}', center: true),
              _cell(monthFmt.format(dt)),
              _cell(_currFmt.format(m.value), right: true),
              _cell('${pct.toStringAsFixed(1)}%', right: true),
            ],
          );
        }),
        _totalRow(3, _currFmt.format(grandTotal), _red, _redLight),
      ],
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

  static pw.TableRow _headerRow(List<String> labels) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: _dark),
      children: labels.asMap().entries.map((e) {
        final isFirst = e.key == 0;
        final isLast = e.key == labels.length - 1;
        return _cell(
          e.value,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          center: isFirst,
          right: isLast && !isFirst,
        );
      }).toList(),
    );
  }

  static pw.TableRow _totalRow(
    int labelSpan,
    String value,
    PdfColor accent,
    PdfColor bg,
  ) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: [
        for (var i = 0; i < labelSpan; i++)
          i == labelSpan - 1
              ? _cell('Total',
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _dark))
              : _cell(''),
        _cell(value,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: accent),
            right: true),
      ],
    );
  }

  static pw.Widget _cell(
    String text, {
    pw.TextStyle? style,
    bool center = false,
    bool right = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: style ?? pw.TextStyle(fontSize: 9, color: _dark),
        textAlign: right
            ? pw.TextAlign.right
            : center
                ? pw.TextAlign.center
                : pw.TextAlign.left,
      ),
    );
  }
}
