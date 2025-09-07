import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/order_model.dart';
import 'event.dart';
import 'state.dart';
import 'dart:developer' as developer; // For logging

// Placeholder for a repository to fetch orders from a server or database
abstract class OrderRepository {
  Future<List<Order>> fetchRecentOrders();
  Future<void> saveOrder(Order order);
}

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrderRepository repository; // Inject repository for data operations

  OrdersBloc({required this.repository}) : super(const OrdersState()) {
    on<AddOrderItem>(_onAddOrderItem);
    on<RemoveOrderItem>(_onRemoveOrderItem);
    on<PlaceOrder>(_onPlaceOrder);
    on<FetchRecentOrders>(_onFetchRecentOrders);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
  }

  /// Handles adding an item to the current order
  void _onAddOrderItem(AddOrderItem event, Emitter<OrdersState> emit) {
    developer.log('Adding order item: ${event.orderItem.menuItem.name}');
    final updatedOrder = Map<OrderItem, int>.from(state.currentOrder);
    updatedOrder[event.orderItem] = (updatedOrder[event.orderItem] ?? 0) + 1;
    emit(state.copyWith(currentOrder: updatedOrder));
  }

  /// Handles removing an item from the current order
  void _onRemoveOrderItem(RemoveOrderItem event, Emitter<OrdersState> emit) {
    developer.log('Removing order item: ${event.orderItem.menuItem.name}');
    final updatedOrder = Map<OrderItem, int>.from(state.currentOrder);
    if (updatedOrder[event.orderItem] != null && updatedOrder[event.orderItem]! > 0) {
      updatedOrder[event.orderItem] = updatedOrder[event.orderItem]! - 1;
      if (updatedOrder[event.orderItem]! <= 0) {
        updatedOrder.remove(event.orderItem);
      }
    }
    emit(state.copyWith(currentOrder: updatedOrder));
  }

  /// Handles placing an order and adding it to recent orders
  void _onPlaceOrder(PlaceOrder event, Emitter<OrdersState> emit) async {
    if (state.currentOrder.isEmpty || event.table == null) {
      developer.log('Cannot place order: Empty order or no table selected');
      return;
    }

    try {
      final total = state.currentOrder.entries
          .map((entry) => (entry.key.menuItem.price * entry.value).toInt())
          .fold<int>(0, (a, b) => a + b);

      final newOrder = Order(
        id: event.orderId.toString(),
        table: event.table!,
        items: Map.from(state.currentOrder),
        total: total,
        timestamp: DateTime.now(),
        status: 'Pending',
      );

      // Save order to repository (e.g., server or database)
      await repository.saveOrder(newOrder);
      developer.log('Order placed: ${newOrder.id} for table ${newOrder.table}');

      final updatedRecentOrders = List<Order>.from(state.recentOrders)..add(newOrder);

      emit(state.copyWith(
        currentOrder: {}, // Clear current order
        recentOrders: updatedRecentOrders,
        status: OrdersStatus.success, // Optional: Add status to OrdersState
      ));
    } catch (e) {
      developer.log('Error placing order: $e', error: e);
      emit(state.copyWith(status: OrdersStatus.error, errorMessage: 'Failed to place order'));
    }
  }

  /// Handles fetching recent orders from the repository
  Future<void> _onFetchRecentOrders(FetchRecentOrders event, Emitter<OrdersState> emit) async {
    try {
      emit(state.copyWith(status: OrdersStatus.loading));
      final recentOrders = await repository.fetchRecentOrders();
      developer.log('Fetched ${recentOrders.length} recent orders');
      emit(state.copyWith(
        recentOrders: recentOrders,
        status: OrdersStatus.success,
      ));
    } catch (e) {
      developer.log('Error fetching recent orders: $e', error: e);
      emit(state.copyWith(
        status: OrdersStatus.error,
        errorMessage: 'Failed to fetch recent orders',
      ));
    }
  }


void _onUpdateOrderStatus(UpdateOrderStatus event, Emitter<OrdersState> emit) {
  final currentOrders = state.recentOrders;

  if (currentOrders == null || currentOrders.isEmpty) {
    print('❌ No recent orders to update.');
    return;
  }

  // Log pre-update state
  print('🔍 Current Orders BEFORE Update:');
  for (var order in currentOrders) {
    print('[BEFORE] Order ID: ${order.id}, Status: ${order.status}');
  }

  // Update the target order's status
  final updatedOrders = currentOrders.map((order) {
    print('[MATCH DEBUG] Comparing: ${order.id} == ${event.orderId}');
    if (order.id == event.orderId) {
      print('✅ MATCH FOUND: Updating Order ID ${order.id} → Status: ${event.status}');
      return order.copyWith(status: event.status);
    }
    return order;
  }).toList();

  // Emit new state
  emit(state.copyWith(recentOrders: updatedOrders));

  // Log post-update state
  print('✅ Orders AFTER Update:');
  for (var order in updatedOrders) {
    print('[AFTER] Order ID: ${order.id}, Status: ${order.status}');
  }

  // Check if update didn't match any ID
  if (!updatedOrders.any((order) => order.id == event.orderId)) {
    print('⚠️ Warning: No order matched the ID: ${event.orderId}');
  }
}

}