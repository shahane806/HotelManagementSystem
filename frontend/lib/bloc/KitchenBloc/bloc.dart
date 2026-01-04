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
    socketService.connect();
    _setupSocketListeners();
    await _fetchOrders(emit);
  }

  /* ---------------- SOCKET EVENTS ---------------- */

  void _onAddNewOrder(
    AddNewOrder event,
    Emitter<KitchenDashboardState> emit,
  ) {
    final exists =
        state.orders.any((o) => o['id'].toString() == event.order['id'].toString());

    if (exists) return;

    final updatedOrders = List<Map<String, dynamic>>.from(state.orders)
      ..insert(0, event.order);

    emit(state.copyWith(orders: updatedOrders));
  }

  void _onUpdateOrderStatus(
    UpdateOrderStatusEvent event,
    Emitter<KitchenDashboardState> emit,
  ) {
    final updatedOrders = state.orders.map((order) {
      if (order['id'].toString() == event.orderId) {
        return {...order, 'status': event.status};
      }
      return order;
    }).toList();

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

  /* ---------------- REFRESH ---------------- */

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<KitchenDashboardState> emit,
  ) async {
    await _fetchOrders(emit);
  }

  /* ---------------- FETCH ORDERS ---------------- */

  Future<void> _fetchOrders(Emitter<KitchenDashboardState> emit) async {
    try {
      final orders = await socketService.fetchOrders();

      if (orders.isNotEmpty && orders.every(_isValidOrder)) {
        emit(state.copyWith(orders: orders));
      }
    } catch (_) {
      // Keep existing state if fetch fails
    }
  }

  /* ---------------- SOCKET LISTENERS ---------------- */

  void _setupSocketListeners() {
    socketService.socket.on('newOrder', (data) {
      final order = Map<String, dynamic>.from(data);
      if (_isValidOrder(order)) {
        add(AddNewOrder(order));
      }
    });

    socketService.socket.on('orderUpdated', (data) {
      final update = Map<String, dynamic>.from(data);
      if (update.containsKey('orderId') &&
          update.containsKey('status')) {
        add(UpdateOrderStatusEvent(
          update['orderId'].toString(),
          update['status'],
        ));
      }
    });

    socketService.socket.on('connect', (_) {
      add(RefreshDashboard());
    });
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
    socketService.disconnect();
    return super.close();
  }
}
