import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/socketService.dart';
import 'event.dart';
import 'state.dart';

class KitchenDashboardBloc extends Bloc<KitchenDashboardEvent, KitchenDashboardState> {
  final SocketService socketService;
  // In-memory cache for orders (could be replaced with persistent storage)
  static List<Map<String, dynamic>> _orderCache = [];

  KitchenDashboardBloc(this.socketService)
      : super(KitchenDashboardState(
          orders: _orderCache,
          selectedStatusFilter: 'All',
          refreshKey: 0,
        )) {
    // Initialize socket connection and listeners
    on<InitializeDashboard>((event, emit) async {
      // If cache has valid orders, use them initially to prevent clearing
      if (_orderCache.isNotEmpty) {
        emit(state.copyWith(
          orders: _orderCache,
          refreshKey: state.refreshKey + 1,
        ));
      }

      // Ensure socket is connected
       socketService.connect();

      // Set up socket listeners
      _setupSocketListeners();

      // Fetch initial orders from the server
      await _fetchOrders(emit);
    });

    // Handle new order
    on<AddNewOrder>((event, emit) {
      final orderExists = state.orders.any((o) => o['id'].toString() == event.order['id'].toString());
      if (!orderExists) {
        final updatedOrders = [...state.orders, event.order];
        _orderCache = updatedOrders.where((order) => order['status'] != 'Served').toList(); // Update cache, exclude Served
        emit(state.copyWith(
          orders: updatedOrders,
          refreshKey: state.refreshKey + 1,
        ));
      } else {
      }
    });

    // Handle order status update
    on<UpdateOrderStatusEvent>((event, emit) {
      final order = state.orders.firstWhere(
        (o) => o['id'].toString() == event.orderId,
        orElse: () => <String, dynamic>{},
      );
      if (order.isEmpty) {
        return;
      }
      if (order['status'] == event.status) {
        return;
      }

      final updatedOrders = state.orders.map((order) {
        if (order['id'].toString() == event.orderId) {
          return {...order, 'status': event.status};
        }
        return order;
      }).toList();
      _orderCache = updatedOrders.where((order) => order['status'] == 'Served').toList(); // Update cache, include Served
      socketService.updateOrderStatus(event.orderId, event.status);
      emit(state.copyWith(
        orders: updatedOrders,
        refreshKey: state.refreshKey + 1,
      ));
    });

    // Handle filter change
    on<ChangeFilter>((event, emit) {
      // Ensure orders are synchronized with cache before emitting
      final currentOrders = state.orders.isNotEmpty ? state.orders : _orderCache;
      emit(state.copyWith(
        orders: currentOrders,
        selectedStatusFilter: event.filter,
        refreshKey: state.refreshKey + 1,
      ));
    });

    // Handle refresh
    on<RefreshDashboard>((event, emit) async {
      await _fetchOrders(emit);
    });

    
    // Trigger initialization
    add(InitializeDashboard());
  }
  // Fetch orders and filter out Served orders with retry logic
    Future<void> _fetchOrders(Emitter<KitchenDashboardState> emit) async {
      const maxRetries = 3;
      const retryDelay = Duration(seconds: 2);
      int attempts = 0;

      while (attempts < maxRetries) {
        try {
          // Fetch orders from the server
          final orders = await socketService.fetchOrders();
          // Validate orders
          if (orders.isNotEmpty && orders.every(_isValidOrder)) {
            final nonServedOrders = orders.where((order) => order['status'] != 'Served').toList();
            _orderCache = nonServedOrders; // Update cache with non-Served orders
            emit(state.copyWith(
              orders: nonServedOrders,
              refreshKey: state.refreshKey + 1,
            ));
            return; // Success, exit the retry loop
          } else {
            emit(state.copyWith(
              orders: _orderCache,
              refreshKey: state.refreshKey + 1,
            ));
            return;
          }
        } catch (e) {
          attempts++;
          if (attempts < maxRetries) {
            await Future.delayed(retryDelay);
          }
        }
      }

      // If all retries fail, retain existing orders to prevent clearing
      emit(state.copyWith(
        orders: state.orders.isNotEmpty ? state.orders : _orderCache,
        refreshKey: state.refreshKey + 1,
      ));
    }

    // Validate order data
    bool _isValidOrder(Map<String, dynamic> order) {
      return order.containsKey('id') &&
          order.containsKey('table') &&
          order.containsKey('items') &&
          order.containsKey('status') &&
          order.containsKey('time') &&
          order.containsKey('total') &&
          order['items'] is List;
    }

    
// Set up socket listeners
    void _setupSocketListeners() {
      socketService.socket.on('newOrder', (order) {
        try {
          final parsedOrder = Map<String, dynamic>.from(order);
          if (!_isValidOrder(parsedOrder)) {
            return;
          }
          add(AddNewOrder(parsedOrder));
        } catch (e) {
        }
      });

      socketService.socket.on('orderUpdated', (data) {
        try {
          final update = Map<String, dynamic>.from(data);
          if (!update.containsKey('orderId') || !update.containsKey('status')) {
            return;
          }
          add(UpdateOrderStatusEvent(update['orderId'].toString(), update['status']));
        } catch (e) {
        }
      });

      socketService.socket.on('connect', (_) {
        add(RefreshDashboard());
      });
    }

  @override
  Future<void> close() {
    socketService.disconnect();
    return super.close();
  }
}