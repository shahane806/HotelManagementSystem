import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/socketService.dart';
import 'event.dart';
import 'state.dart';

class KitchenDashboardBloc
    extends Bloc<KitchenDashboardEvent, KitchenDashboardState> {
  final SocketService socketService;

  KitchenDashboardBloc(this.socketService)
      : super(const KitchenDashboardState(
          orders: [],
          selectedStatusFilter: 'All',
        )) {
    on<InitializeDashboard>(_onInitializeDashboard);
    on<AddNewOrder>(_onAddNewOrder);
    on<UpdateOrderStatusEvent>(_onUpdateOrderStatus);
    on<ChangeFilter>(_onChangeFilter);
    on<RefreshDashboard>(_onRefreshDashboard);
  }

  /* ---------------- INITIALIZE ---------------- */

  Future<void> _onInitializeDashboard(
    InitializeDashboard event,
    Emitter<KitchenDashboardState> emit,
  ) async {
    // Connect to socket (if not already connected)
    socketService.connect();

    // Load initial orders
    await _fetchOrders(emit);
  }

  /* ---------------- SOCKET EVENTS (handled via SocketService) ---------------- */

  void _onAddNewOrder(
    AddNewOrder event,
    Emitter<KitchenDashboardState> emit,
  ) {
    // Prevent duplicate orders
    final exists = state.orders.any(
      (o) => o['id']?.toString() == event.order['id']?.toString(),
    );

    if (exists) return;

    // Add new order at the top
    final updatedOrders = List<Map<String, dynamic>>.from(state.orders)
      ..insert(0, event.order);

    emit(state.copyWith(orders: updatedOrders));
  }

  void _onUpdateOrderStatus(
    UpdateOrderStatusEvent event,
    Emitter<KitchenDashboardState> emit,
  ) {
    // Update only the matching order
    final updatedOrders = state.orders.map((order) {
      if (order['id']?.toString() == event.orderId ||
          order['_id']?.toString() == event.orderId) {
        return {
          ...order,
          'status': event.status,
        };
      }
      return order;
    }).toList();

    // Also send the update to the server (if this came from UI action)
    socketService.updateOrderStatus(event.orderId, event.status);

    emit(state.copyWith(orders: updatedOrders));
  }

  /* ---------------- FILTER ---------------- */

  void _onChangeFilter(
    ChangeFilter event,
    Emitter<KitchenDashboardState> emit,
  ) {
    emit(state.copyWith(selectedStatusFilter: event.filter));
  }

  /* ---------------- REFRESH (manual or reconnect) ---------------- */

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<KitchenDashboardState> emit,
  ) async {
    await _fetchOrders(emit);
  }

  /* ---------------- FETCH ORDERS (initial & manual refresh) ---------------- */

  Future<void> _fetchOrders(Emitter<KitchenDashboardState> emit) async {
    try {
      final orders = await socketService.fetchOrders();

      if (orders.isNotEmpty && orders.every(_isValidOrder)) {
        emit(state.copyWith(orders: orders));
      }
    } catch (e) {
      // Keep current state on failure (don't crash UI)
      // Optionally log error: print('Fetch orders failed: $e');
    }
  }

  /* ---------------- VALIDATION ---------------- */

  bool _isValidOrder(Map<String, dynamic> order) {
    return order.containsKey('id') &&
        order.containsKey('table') &&
        order.containsKey('status') &&
        order.containsKey('createdAt') &&
        order.containsKey('total') &&
        order['items'] is List;
  }

  @override
  Future<void> close() {
    // Optional: only disconnect if you want to fully close socket when bloc dies
    // socketService.disconnect();
    return super.close();
  }
}
