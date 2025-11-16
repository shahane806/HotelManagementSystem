import '../../models/order_model.dart';

enum OrdersStatus { initial, loading, success, error }

class OrdersState {
  final Map<OrderItem, int> currentOrder;
  final List<Order> recentOrders;
  final OrdersStatus status;
  final String? errorMessage;
  const OrdersState({
    this.currentOrder = const {},
    this.recentOrders = const [],
    this.status = OrdersStatus.initial,
    this.errorMessage,
  });

  OrdersState copyWith({
    Map<OrderItem, int>? currentOrder,
    List<Order>? recentOrders,
    OrdersStatus? status,
    String? errorMessage,
  }) {
    return OrdersState(
      currentOrder: currentOrder ?? this.currentOrder,
      recentOrders: recentOrders ?? this.recentOrders,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}