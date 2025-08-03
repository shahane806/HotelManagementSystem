import '../../models/order_model.dart';
import '../bloc/OrderBloc/bloc.dart';

class InMemoryOrderRepository implements OrderRepository {
  final List<Order> _orders = [];

  @override
  Future<List<Order>> fetchRecentOrders() async {
    // Simulate network delay for realism
    await Future.delayed(const Duration(milliseconds: 500));
    return List<Order>.from(_orders);
  }

  @override
  Future<void> saveOrder(Order order) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    _orders.add(order);
  }

  // Optional: Method to fetch a single order by ID (for handling socket updates)
  Future<Order?> fetchOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _orders.firstWhere(
      (order) => order.id == orderId,
      orElse: () => null as Order,
    );
  }
}