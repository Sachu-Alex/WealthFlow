import 'dart:convert';

class BillItem {
  final String id;
  String name;
  int quantity;
  double unitPrice;
  double total;
  bool isShared;

  BillItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.isShared = false,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
        id: json['id'] as String? ?? _generateId(),
        name: json['name'] as String? ?? 'Unknown Item',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        isShared: json['is_shared'] as bool? ?? false,
      );

  static String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  BillItem copyWith({
    String? name,
    int? quantity,
    double? unitPrice,
    double? total,
    bool? isShared,
  }) =>
      BillItem(
        id: id,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        total: total ?? this.total,
        isShared: isShared ?? this.isShared,
      );
}

class BillSummary {
  final List<BillItem> items;
  final double subtotal;
  final double tax;
  final double serviceCharge;
  final double grandTotal;

  const BillSummary({
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.grandTotal,
  });

  factory BillSummary.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((e) => BillItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return BillSummary(
      items: itemsList,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      serviceCharge: (json['service_charge'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  BillSummary copyWithItems(List<BillItem> newItems) {
    final sub = newItems.fold<double>(0, (s, i) => s + i.total);
    return BillSummary(
      items: newItems,
      subtotal: sub,
      tax: tax,
      serviceCharge: serviceCharge,
      grandTotal: sub + tax + serviceCharge,
    );
  }
}

class SplitParticipant {
  final String name;
  final List<String> itemsConsumed;
  final double subtotal;
  final double taxShare;
  final double serviceChargeShare;
  final double total;

  const SplitParticipant({
    required this.name,
    required this.itemsConsumed,
    required this.subtotal,
    required this.taxShare,
    required this.serviceChargeShare,
    required this.total,
  });

  factory SplitParticipant.fromJson(Map<String, dynamic> json) =>
      SplitParticipant(
        name: json['name'] as String? ?? 'Unknown',
        itemsConsumed: (json['items_consumed'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
        taxShare: (json['tax_share'] as num?)?.toDouble() ?? 0.0,
        serviceChargeShare:
            (json['service_charge_share'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
      );
}

class SplitResult {
  final List<SplitParticipant> participants;
  final List<String> sharedItems;
  final double grandTotal;
  final double confidence;
  final String? notes;

  const SplitResult({
    required this.participants,
    required this.sharedItems,
    required this.grandTotal,
    required this.confidence,
    this.notes,
  });

  factory SplitResult.fromJson(Map<String, dynamic> json) => SplitResult(
        participants: (json['participants'] as List<dynamic>? ?? [])
            .map((e) => SplitParticipant.fromJson(e as Map<String, dynamic>))
            .toList(),
        sharedItems: (json['shared_items'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
        notes: json['notes'] as String?,
      );
}

// Safely parse JSON that may be wrapped in markdown code blocks
Map<String, dynamic> parseGeminiJson(String text) {
  // Strip markdown code fences if present
  var cleaned = text.trim();
  if (cleaned.startsWith('```')) {
    cleaned = cleaned.replaceAll(RegExp(r'^```[a-z]*\n?'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\n?```$'), '');
  }
  return json.decode(cleaned.trim()) as Map<String, dynamic>;
}
