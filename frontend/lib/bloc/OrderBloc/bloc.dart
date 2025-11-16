import 'dart:async';

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
  final OrderRepository repository;
  OrdersBloc({required this.repository}) : super(const OrdersState()) {
    on<AddOrderItem>(_onAddOrderItem);
    on<RemoveOrderItem>(_onRemoveOrderItem);
    on<PlaceOrder>(_onPlaceOrder);
    on<FetchRecentOrders>(_onFetchRecentOrders);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<RemoveRecentOrder>(_onRemoveRecentOrder);
  }

  @override
  Future<void> close() {
    return super.close();
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
    if (updatedOrder[event.orderItem] != null &&
        updatedOrder[event.orderItem]! > 0) {
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

      final updatedRecentOrders = List<Order>.from(state.recentOrders)
        ..add(newOrder);

      emit(state.copyWith(
        currentOrder: {}, // Clear current order
        recentOrders: updatedRecentOrders,
        status: OrdersStatus.success, // Optional: Add status to OrdersState
      ));
    } catch (e) {
      developer.log('Error placing order: $e', error: e);
      emit(state.copyWith(
          status: OrdersStatus.error, errorMessage: 'Failed to place order'));
    }
  }

  /// Handles fetching recent orders from the repository
  Future<void> _onFetchRecentOrders(
      FetchRecentOrders event, Emitter<OrdersState> emit) async {
    try {
      emit(state.copyWith(status: OrdersStatus.loading));
      final recentOrders = await repository.fetchRecentOrders();
      final filteredOrders = recentOrders.where((order) {
        return order.status != 'Paid' && order.status != 'Completed';
      }).toList();
      developer.log('Fetched ${recentOrders.length} recent orders');
      emit(state.copyWith(
        recentOrders: filteredOrders,
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
  final current = state.recentOrders;
  if (current.isEmpty) return;

  const terminal = {'Paid', 'Completed', 'Cancelled'};
  final newStatus = event.status;
  final id        = event.orderId;

  if (terminal.contains(newStatus)) {
    emit(state.copyWith(recentOrders: current.where((o) => o.id != id).toList()));
    return;
  }

  final idx = current.indexWhere((o) => o.id == id);
  if (idx == -1) return;

  final updated = List<Order>.from(current);
  updated[idx] = current[idx].copyWith(status: newStatus);
  emit(state.copyWith(recentOrders: updated));
}
  void _onRemoveRecentOrder(
      RemoveRecentOrder event, Emitter<OrdersState> emit) {
    final updated =
        state.recentOrders.where((o) => o.id != event.orderId).toList();
    emit(state.copyWith(recentOrders: updated));
  }



}
