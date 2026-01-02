class KitchenDashboardState {
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>>? servedOrders;
  final String selectedStatusFilter;
  final int refreshKey;

  KitchenDashboardState({
    required this.orders,
    this.servedOrders,
    required this.selectedStatusFilter,
    required this.refreshKey,
  });

  KitchenDashboardState copyWith({
    List<Map<String, dynamic>>? orders,
    List<Map<String, dynamic>>? servedOrders,
    String? selectedStatusFilter,
    int? refreshKey,
  }) {
    return KitchenDashboardState(
      orders: orders ?? this.orders,
      servedOrders: servedOrders ?? this.servedOrders,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}