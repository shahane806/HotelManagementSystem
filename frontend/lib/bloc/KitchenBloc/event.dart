abstract class KitchenDashboardEvent {}

class InitializeDashboard extends KitchenDashboardEvent {}

class AddNewOrder extends KitchenDashboardEvent {
  final Map<String, dynamic> order;

  AddNewOrder(this.order);
}

class UpdateOrderStatusEvent extends KitchenDashboardEvent {
  final String orderId;
  final String status;

  UpdateOrderStatusEvent(this.orderId, this.status);
}

class ChangeFilter extends KitchenDashboardEvent {
  final String filter;

  ChangeFilter(this.filter);
}

class RefreshDashboard extends KitchenDashboardEvent {}
class SetOrdersEvent extends KitchenDashboardEvent {
  final List<Map<String, dynamic>> orders;

  SetOrdersEvent(this.orders);
}
