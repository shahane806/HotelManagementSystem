class BillState {
  final List<Map<String, dynamic>> bills;
  final bool isLoading;
  final String? error;

  BillState({
    this.bills = const [],
    this.isLoading = false,
    this.error,
  });

  BillState copyWith({
    List<Map<String, dynamic>>? bills,
    bool? isLoading,
    String? error,
  }) {
    return BillState(
      bills: bills ?? this.bills,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
