class KitchenDashboardState {
  final List<Map<String, dynamic>> orders;
  final String selectedStatusFilter;

  const KitchenDashboardState({
    required this.orders,
    required this.selectedStatusFilter,
  });

  KitchenDashboardState copyWith({
    List<Map<String, dynamic>>? orders,
    String? selectedStatusFilter,
  }) {
    return KitchenDashboardState(
      orders: orders ?? this.orders,
      selectedStatusFilter:
          selectedStatusFilter ?? this.selectedStatusFilter,
    );
  }
}
