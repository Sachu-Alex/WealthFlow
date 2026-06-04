import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/bill_splitter.dart';

// 100% free, on-device — no API key, no internet, no billing account.
class ReceiptService {
  // ── OCR: extract raw text from receipt image ──────────────────────────────

  Future<BillSummary> extractFromImage(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);
      return _parseReceiptText(result.text);
    } finally {
      recognizer.close();
    }
  }

  // ── Receipt text parser ───────────────────────────────────────────────────
  // Handles common Indian restaurant/grocery receipt formats:
  //   "Chicken Biryani    2    250   500.00"
  //   "Fried Rice                   180"
  //   "2 x Coke                      90"

  BillSummary _parseReceiptText(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final items = <BillItem>[];
    double tax = 0;
    double serviceCharge = 0;
    double grandTotal = 0;

    // Matches trailing price: optional ₹/Rs, digits, optional decimal
    final priceRe = RegExp(r'(?:₹|Rs\.?\s*)?(\d{1,6}(?:[.,]\d{1,2})?)\s*$');
    // Detects totals / non-item lines
    final skipRe = RegExp(
        r'\b(total|subtotal|sub\s*total|bill\s*amount|amount\s*due|net\s*amount|round|discount|welcome|thank|table|order|date|time|phone|address|gstin|fssai|vat)\b',
        caseSensitive: false);
    final taxRe = RegExp(
        r'\b(gst|cgst|sgst|tax|cess|levy|surcharge)\b',
        caseSensitive: false);
    final svcRe = RegExp(
        r'\b(service\s*charge|service\s*tax|sc)\b',
        caseSensitive: false);
    final grandRe = RegExp(
        r'\b(grand\s*total|total\s*amount|total\s*bill|net\s*payable|amount\s*payable|total)\b',
        caseSensitive: false);
    // Quantity prefix: "2x Item" or "2 x Item" or "Qty: 2 Item"
    final qtyPrefixRe = RegExp(r'^(\d+)\s*[xX×]\s*(.+)$');

    for (final line in lines) {
      final priceMatch = priceRe.firstMatch(line);
      if (priceMatch == null) continue;

      final rawPrice = priceMatch.group(1)!.replaceAll(',', '.');
      final price = double.tryParse(rawPrice);
      if (price == null || price <= 0) continue;

      final namePart =
          line.substring(0, priceMatch.start).replaceAll(RegExp(r'[\.\-_]{2,}'), '').trim();
      if (namePart.isEmpty) continue;

      // Grand total line
      if (grandRe.hasMatch(namePart)) {
        if (price > grandTotal) grandTotal = price;
        continue;
      }

      // Tax line
      if (taxRe.hasMatch(namePart)) {
        tax += price;
        continue;
      }

      // Service charge line
      if (svcRe.hasMatch(namePart)) {
        serviceCharge += price;
        continue;
      }

      // Skip non-item lines
      if (skipRe.hasMatch(namePart)) continue;

      // Very short or numeric-only names are likely artifacts
      if (namePart.length < 2 || RegExp(r'^\d+$').hasMatch(namePart)) continue;

      // Check for quantity prefix like "2 x Biryani"
      int qty = 1;
      String itemName = namePart;
      final qtyMatch = qtyPrefixRe.firstMatch(namePart);
      if (qtyMatch != null) {
        qty = int.tryParse(qtyMatch.group(1)!) ?? 1;
        itemName = qtyMatch.group(2)!.trim();
      }

      items.add(BillItem(
        id: items.length.toString(),
        name: _titleCase(itemName),
        quantity: qty,
        unitPrice: price / qty,
        total: price,
      ));
    }

    final subtotal = items.fold<double>(0, (s, i) => s + i.total);
    if (grandTotal == 0) grandTotal = subtotal + tax + serviceCharge;

    return BillSummary(
      items: items,
      subtotal: subtotal,
      tax: tax,
      serviceCharge: serviceCharge,
      grandTotal: grandTotal,
    );
  }

  String _titleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  // ── Pure Dart split calculator ────────────────────────────────────────────
  // assignments: itemId → set of participant names who had that item
  // Empty set = shared equally by all participants

  SplitResult calculateSplit({
    required BillSummary bill,
    required List<String> participants,
    required Map<String, Set<String>> assignments,
  }) {
    if (participants.isEmpty) {
      return SplitResult(
        participants: [],
        sharedItems: [],
        grandTotal: bill.grandTotal,
        confidence: 1.0,
      );
    }

    // Accumulate subtotals per person
    final subtotals = <String, double>{for (final p in participants) p: 0.0};
    final personItems = <String, List<String>>{for (final p in participants) p: []};
    final sharedItemNames = <String>[];

    for (final item in bill.items) {
      final assigned = assignments[item.id] ?? {};
      // Empty assignment → split equally among everyone
      final people =
          assigned.isEmpty ? participants : assigned.toList();

      if (people.length > 1 || assigned.isEmpty) {
        sharedItemNames.add(item.name);
      }

      final share = item.total / people.length;
      for (final p in people) {
        if (subtotals.containsKey(p)) {
          subtotals[p] = subtotals[p]! + share;
          personItems[p]!.add(item.name);
        }
      }
    }

    final totalSubtotal =
        subtotals.values.fold<double>(0, (a, b) => a + b);

    final result = participants.map((name) {
      final sub = subtotals[name] ?? 0;
      final proportion =
          totalSubtotal > 0 ? sub / totalSubtotal : 1 / participants.length;
      final taxShare = bill.tax * proportion;
      final svcShare = bill.serviceCharge * proportion;
      return SplitParticipant(
        name: name,
        itemsConsumed: personItems[name] ?? [],
        subtotal: sub,
        taxShare: taxShare,
        serviceChargeShare: svcShare,
        total: sub + taxShare + svcShare,
      );
    }).toList();

    return SplitResult(
      participants: result,
      sharedItems: sharedItemNames.toSet().toList(),
      grandTotal: result.fold<double>(0, (s, p) => s + p.total),
      confidence: 1.0,
    );
  }
}
