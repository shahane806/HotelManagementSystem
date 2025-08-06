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
      print('Initializing KitchenDashboardBloc');
      // If cache has valid orders, use them initially to prevent clearing
      if (_orderCache.isNotEmpty) {
        print('Using existing cache with ${_orderCache.length} orders: $_orderCache');
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
        print('[SOCKET] New order added: ${event.order['id']}');
        final updatedOrders = [...state.orders, event.order];
        _orderCache = updatedOrders.where((order) => order['status'] != 'Served').toList(); // Update cache, exclude Served
        print('Updated _orderCache with ${_orderCache.length} orders: $_orderCache');
        emit(state.copyWith(
          orders: updatedOrders,
          refreshKey: state.refreshKey + 1,
        ));
      } else {
        print('[SOCKET] Order already exists, skipping: ${event.order['id']}');
      }
    });

    // Handle order status update
    on<UpdateOrderStatusEvent>((event, emit) {
      print('Processing UpdateOrderStatusEvent: orderId=${event.orderId}, status=${event.status}');
      final order = state.orders.firstWhere(
        (o) => o['id'].toString() == event.orderId,
        orElse: () => <String, dynamic>{},
      );
      if (order.isEmpty) {
        print('Order ${event.orderId} not found, skipping update');
        return;
      }
      if (order['status'] == event.status) {
        print('Order ${event.orderId} already has status ${event.status}, skipping update');
        return;
      }

      print('Updating order status: orderId=${event.orderId}, status=${event.status}');
      final updatedOrders = state.orders.map((order) {
        if (order['id'].toString() == event.orderId) {
          print('[SOCKET] Updating order ${event.orderId} to status: ${event.status}');
          return {...order, 'status': event.status};
        }
        return order;
      }).toList();
      _orderCache = updatedOrders.where((order) => order['status'] != 'Served').toList(); // Update cache, exclude Served
      print('Updated _orderCache with ${_orderCache.length} orders: $_orderCache');
      socketService.updateOrderStatus(event.orderId, event.status);
      emit(state.copyWith(
        orders: updatedOrders,
        refreshKey: state.refreshKey + 1,
      ));
    });

    // Handle filter change
    on<ChangeFilter>((event, emit) {
      print('Filter changed to: ${event.filter}, current orders: ${state.orders.length}');
      // Ensure orders are synchronized with cache before emitting
      final currentOrders = state.orders.isNotEmpty ? state.orders : _orderCache;
      emit(state.copyWith(
        orders: currentOrders,
        selectedStatusFilter: event.filter,
        refreshKey: state.refreshKey + 1,
      ));
      print('Emitted state with filter: ${event.filter}, orders: ${currentOrders.length}');
    });

    // Handle refresh
    on<RefreshDashboard>((event, emit) async {
      print('Refreshing dashboard, current orders: ${state.orders.length}');
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
          print('Fetching orders, attempt ${attempts + 1}/$maxRetries');
          // Fetch orders from the server
          final orders = await socketService.fetchOrders();
          // Validate orders
          if (orders.isNotEmpty && orders.every(_isValidOrder)) {
            final nonServedOrders = orders.where((order) => order['status'] != 'Served').toList();
            _orderCache = nonServedOrders; // Update cache with non-Served orders
            print('Fetched ${nonServedOrders.length} non-served orders: $nonServedOrders');
            emit(state.copyWith(
              orders: nonServedOrders,
              refreshKey: state.refreshKey + 1,
            ));
            return; // Success, exit the retry loop
          } else {
            print('Invalid or empty orders received, falling back to cache');
            emit(state.copyWith(
              orders: _orderCache,
              refreshKey: state.refreshKey + 1,
            ));
            return;
          }
        } catch (e) {
          attempts++;
          print('Error fetching orders (attempt $attempts/$maxRetries): $e');
          if (attempts < maxRetries) {
            print('Retrying in ${retryDelay.inSeconds} seconds...');
            await Future.delayed(retryDelay);
          }
        }
      }

      // If all retries fail, retain existing orders to prevent clearing
      print('All fetch attempts failed, retaining existing orders: ${state.orders.length}');
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
        print('Received newOrder: $order');
        try {
          final parsedOrder = Map<String, dynamic>.from(order);
          if (!_isValidOrder(parsedOrder)) {
            print('Invalid order data, skipping: $parsedOrder');
            return;
          }
          add(AddNewOrder(parsedOrder));
        } catch (e) {
          print('Error parsing newOrder: $e');
        }
      });

      socketService.socket.on('orderUpdated', (data) {
        print('Received orderUpdated: $data');
        try {
          final update = Map<String, dynamic>.from(data);
          if (!update.containsKey('orderId') || !update.containsKey('status')) {
            print('Invalid update data, skipping: $update');
            return;
          }
          add(UpdateOrderStatusEvent(update['orderId'].toString(), update['status']));
        } catch (e) {
          print('Error parsing orderUpdated: $e');
        }
      });

      socketService.socket.on('connect', (_) {
        print('Socket reconnected, fetching orders');
        add(RefreshDashboard());
      });
    }

  @override
  Future<void> close() {
    print('Disposing KitchenDashboardBloc');
    socketService.disconnect();
    return super.close();
  }
}