class KitchenDashboardState {
  final List<Map<String, dynamic>> orders;
  final String selectedStatusFilter;
  final int refreshKey;

  KitchenDashboardState({
    required this.orders,
    required this.selectedStatusFilter,
    required this.refreshKey,
  });

  KitchenDashboardState copyWith({
    List<Map<String, dynamic>>? orders,
    String? selectedStatusFilter,
    int? refreshKey,
  }) {
    return KitchenDashboardState(
      orders: orders ?? this.orders,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}