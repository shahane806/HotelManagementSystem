import '../../models/order_model.dart';
import '../models/menu_model.dart';
import '../bloc/OrderBloc/bloc.dart';
import '../services/socketService.dart';

class InMemoryOrderRepository implements OrderRepository {
  final SocketService _socketService = SocketService();

  @override
  Future<List<Order>> fetchRecentOrders() async {
    try {
      // Fetch orders from backend via Socket.IO
      final ordersData = await _socketService.fetchOrders();
      print("Orders Fetched (RAW) : $ordersData");

      // Convert socket data to Order objects
      return ordersData.map<Order>((orderData) {
        final Map<OrderItem, int> items = {};

        // --- SAFETY: ensure items is a List ---
        if (orderData['items'] != null && orderData['items'] is List) {
          final List<Map<String, dynamic>> itemsList =
              List<Map<String, dynamic>>.from(orderData['items']);

          for (final item in itemsList) {
            final menuItem = MenuItem(
              name: item['name'] ?? '',
              price: (item['price'] ?? 0).toInt(),
              category: '', // Not available from backend
              description: '',
              image: '',
              type: '',
            );

            final orderItem = OrderItem(
              menuItem: menuItem,
              customization: item['customization'] ?? '',
            );

            items[orderItem] = (item['quantity'] ?? 1).toInt();
          }
        }

        // --- CRITICAL FIX: table MUST be mapped ---
        final String tableName = orderData['table'] ?? '';

        if (tableName.isEmpty) {
          print(
            '⚠️ WARNING: Order ${orderData['_id']} has empty table value',
          );
        }

        return Order(
          id: orderData['_id'] ?? '',
          table: tableName, // ✅ FIXED
          items: items,
          total: (orderData['total'] ?? 0).toInt(),
          timestamp: orderData['createdAt'] != null
              ? DateTime.parse(orderData['createdAt'])
              : DateTime.now(),
          status: orderData['status'] ?? 'Pending',
        );
      }).toList();
    } catch (e, stack) {
      print('❌ Error fetching recent orders: $e');
      print(stack);
      return [];
    }
  }

  @override
  Future<void> saveOrder(Order order) async {
    // Order is saved via Socket.IO placeOrder event
    // Backend persists it — no local storage needed
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Optional: Fetch a single order by ID (used for socket updates)
  Future<Order?> fetchOrderById(String orderId) async {
    try {
      final orders = await fetchRecentOrders();
      return orders.firstWhere(
        (order) => order.id == orderId,
      );
    } catch (_) {
      return null;
    }
  }
}
