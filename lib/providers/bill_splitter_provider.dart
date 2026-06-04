import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/bill_splitter.dart';
import '../data/services/receipt_service.dart';

enum SplitterStep { upload, reviewItems, assign, results }

class BillSplitterState {
  final SplitterStep step;
  final XFile? receiptImage;
  final bool isLoading;
  final String loadingMessage;
  final BillSummary? billSummary;

  // Step 3: who had what
  final List<String> participants;
  // itemId → set of participant names (empty = shared equally by all)
  final Map<String, Set<String>> assignments;

  final SplitResult? splitResult;
  final String? error;

  const BillSplitterState({
    this.step = SplitterStep.upload,
    this.receiptImage,
    this.isLoading = false,
    this.loadingMessage = '',
    this.billSummary,
    this.participants = const [],
    this.assignments = const {},
    this.splitResult,
    this.error,
  });

  BillSplitterState copyWith({
    SplitterStep? step,
    XFile? receiptImage,
    bool? isLoading,
    String? loadingMessage,
    BillSummary? billSummary,
    List<String>? participants,
    Map<String, Set<String>>? assignments,
    SplitResult? splitResult,
    String? error,
    bool clearError = false,
  }) =>
      BillSplitterState(
        step: step ?? this.step,
        receiptImage: receiptImage ?? this.receiptImage,
        isLoading: isLoading ?? this.isLoading,
        loadingMessage: loadingMessage ?? this.loadingMessage,
        billSummary: billSummary ?? this.billSummary,
        participants: participants ?? this.participants,
        assignments: assignments ?? this.assignments,
        splitResult: splitResult ?? this.splitResult,
        error: clearError ? null : error ?? this.error,
      );
}

class BillSplitterNotifier extends Notifier<BillSplitterState> {
  final _service = ReceiptService();
  final _picker = ImagePicker();

  @override
  BillSplitterState build() => const BillSplitterState();

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
      );
      if (file == null) return;
      state = state.copyWith(receiptImage: file, clearError: true);
    } catch (e) {
      state = state.copyWith(error: 'Could not access camera/gallery: $e');
    }
  }

  // ── Step 1 → 2: OCR scan ──────────────────────────────────────────────────

  Future<void> scanReceipt() async {
    if (state.receiptImage == null) return;
    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Scanning receipt…',
      clearError: true,
    );
    try {
      final summary =
          await _service.extractFromImage(state.receiptImage!.path);
      if (summary.items.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not read items from this image. Try a clearer photo, or add items manually.',
          billSummary: summary,
          step: SplitterStep.reviewItems,
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        billSummary: summary,
        step: SplitterStep.reviewItems,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Scan failed: $e',
      );
    }
  }

  // ── Manual bill entry fallback ────────────────────────────────────────────

  void startManualEntry() {
    state = state.copyWith(
      billSummary: const BillSummary(
        items: [],
        subtotal: 0,
        tax: 0,
        serviceCharge: 0,
        grandTotal: 0,
      ),
      step: SplitterStep.reviewItems,
      clearError: true,
    );
  }

  // ── Item editing ──────────────────────────────────────────────────────────

  void updateItem(BillItem updated) {
    final items = state.billSummary!.items
        .map((i) => i.id == updated.id ? updated : i)
        .toList();
    state = state.copyWith(billSummary: state.billSummary!.copyWithItems(items));
  }

  void removeItem(String id) {
    final items =
        state.billSummary!.items.where((i) => i.id != id).toList();
    state = state.copyWith(billSummary: state.billSummary!.copyWithItems(items));
    // Remove from assignments
    final newAssign = Map<String, Set<String>>.from(state.assignments)
      ..remove(id);
    state = state.copyWith(assignments: newAssign);
  }

  void addItem() {
    final items = List<BillItem>.from(state.billSummary!.items)
      ..add(BillItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Item ${state.billSummary!.items.length + 1}',
        quantity: 1,
        unitPrice: 0,
        total: 0,
      ));
    state = state.copyWith(billSummary: state.billSummary!.copyWithItems(items));
  }

  void proceedToAssign() =>
      state = state.copyWith(step: SplitterStep.assign, clearError: true);

  // ── Participants ──────────────────────────────────────────────────────────

  void addParticipant(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || state.participants.contains(trimmed)) return;
    state = state.copyWith(participants: [...state.participants, trimmed]);
  }

  void removeParticipant(String name) {
    final updated =
        state.participants.where((p) => p != name).toList();
    // Remove from all assignments
    final newAssign = state.assignments.map((itemId, people) =>
        MapEntry(itemId, Set<String>.from(people)..remove(name)));
    state = state.copyWith(participants: updated, assignments: newAssign);
  }

  // ── Item assignments ──────────────────────────────────────────────────────

  void toggleAssignment(String itemId, String participant) {
    final current = Set<String>.from(state.assignments[itemId] ?? {});
    if (current.contains(participant)) {
      current.remove(participant);
    } else {
      current.add(participant);
    }
    final newAssign = Map<String, Set<String>>.from(state.assignments)
      ..[itemId] = current;
    state = state.copyWith(assignments: newAssign);
  }

  void setSharedByAll(String itemId) {
    // Empty set = shared by all
    final newAssign = Map<String, Set<String>>.from(state.assignments)
      ..[itemId] = {};
    state = state.copyWith(assignments: newAssign);
  }

  bool isAssignedTo(String itemId, String participant) =>
      state.assignments[itemId]?.contains(participant) ?? false;

  bool isSharedByAll(String itemId) =>
      state.assignments.containsKey(itemId) &&
      (state.assignments[itemId]?.isEmpty ?? false);

  // ── Step 3 → 4: Calculate ────────────────────────────────────────────────

  void calculateSplit() {
    if (state.billSummary == null || state.participants.isEmpty) return;

    final result = _service.calculateSplit(
      bill: state.billSummary!,
      participants: state.participants,
      assignments: state.assignments,
    );
    state = state.copyWith(splitResult: result, step: SplitterStep.results);
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void goBack() {
    switch (state.step) {
      case SplitterStep.reviewItems:
        state = state.copyWith(step: SplitterStep.upload);
      case SplitterStep.assign:
        state = state.copyWith(step: SplitterStep.reviewItems);
      case SplitterStep.results:
        state = state.copyWith(step: SplitterStep.assign);
      case SplitterStep.upload:
        break;
    }
  }

  void reset() => state = const BillSplitterState();
}

final billSplitterProvider =
    NotifierProvider<BillSplitterNotifier, BillSplitterState>(
  BillSplitterNotifier.new,
);
