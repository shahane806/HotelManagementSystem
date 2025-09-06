import 'dart:async';
import 'dart:math';
import 'package:frontend/app/api_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../bloc/KitchenBloc/bloc.dart';
import '../bloc/KitchenBloc/event.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;
  KitchenDashboardBloc? bloc; // Store BLoC instance
 List<Map<String, dynamic>> _eventQueue = [];
  List<Map<String, dynamic>> _lastKnownOrders = []; // Cache for last valid orders
  List<Map<String, dynamic>> _lastKnownBills = []; // Cache for last valid bills// Cache for last valid orders
  bool _isProcessingQueue = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);

  factory SocketService([KitchenDashboardBloc? bloc]) {
    _instance.bloc = bloc ?? _instance.bloc;
    return _instance;
  }

  SocketService._internal() {
    socket = IO.io(
      ApiConstants.socketUrl, // Update with your actual server URL
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      print('✅ Connected to socket server with ID: ${socket.id}');
      _reconnectAttempts = 0; // Reset reconnect attempts on successful connection
      _processEventQueue();
      // Emit event to fetch initial orders
      socket.emit('fetchOrders');
    });

    socket.onDisconnect((_) {
      print('❌ Disconnected from socket server');
      _attemptReconnect();
    });

    socket.onConnectError((data) {
      print('⚠️ Connect error: $data');
      _attemptReconnect();
    });

    socket.onError((data) {
      print('❗ Socket error: $data');
    });

    socket.on('newOrder', (data) {
      print('📥 New order received: $data');
      try {
        final parsedOrder = Map<String, dynamic>.from(data);
        if (_isValidOrder(parsedOrder)) {
          _eventQueue.add({'event': 'newOrder', 'data': parsedOrder});
          _processEventQueue();
        } else {
          print('Invalid order data, skipping: $parsedOrder');
        }
      } catch (e) {
        print('Error parsing newOrder: $e');
      }
    });

    socket.on('orderUpdated', (data) {
      print('📤 Order status updated: $data');
      try {
        final update = Map<String, dynamic>.from(data);
        if (_isValidUpdate(update)) {
          _eventQueue.add({'event': 'orderUpdated', 'data': update});
          _processEventQueue();
        } else {
          print('Invalid update data, skipping: $update');
        }
      } catch (e) {
        print('Error parsing orderUpdated: $e');
      }
    });

    socket.on('ordersFetched', (data) {
      print('📋 Orders fetched: $data');
      try {
        final orders = List<Map<String, dynamic>>.from(data);
        if (orders.every(_isValidOrder)) {
          _lastKnownOrders = orders; // Update last known orders
          _eventQueue.add({'event': 'ordersFetched', 'data': orders});
          _processEventQueue();
        } else {
          print('Invalid orders data, skipping: $orders');
          _eventQueue.add({'event': 'ordersFetched', 'data': _lastKnownOrders});
          _processEventQueue();
        }
      } catch (e) {
        print('Error parsing ordersFetched: $e');
        _eventQueue.add({'event': 'ordersFetched', 'data': _lastKnownOrders});
        _processEventQueue();
      }
    });
socket.on('billsFetched', (data) {
      print('📋 Bills fetched: $data');
      try {
        final bills = List<Map<String, dynamic>>.from(data);
        if (bills.every(_isValidBill)) {
          _lastKnownBills = bills; // Update last known bills
          _eventQueue.add({'event': 'billsFetched', 'data': bills});
          _processEventQueue();
        } else {
          print('Invalid bills data, skipping: $bills');
          _eventQueue.add({'event': 'billsFetched', 'data': _lastKnownBills});
          _processEventQueue();
        }
      } catch (e) {
        print('Error parsing billsFetched: $e');
        _eventQueue.add({'event': 'billsFetched', 'data': _lastKnownBills});
        _processEventQueue();
      }
    });
    socket.on('billPaid', (data) {
      print('💳 Bill paid: $data');
      try {
        // final billData = Map<String, dynamic>.from(data);
        // You can add logic here to handle bill paid event, e.g., notify BLoC
        if (bloc != null) {
          // Assuming you have a BLoC event for bill paid
          // bloc!.add(BillPaidEvent(billData));
        }
      } catch (e) {
        print('Error parsing billPaid: $e');
      }
    });
  }

  /// Validates order data
  bool _isValidOrder(Map<String, dynamic> order) {
    return order.containsKey('id') &&
        order.containsKey('table') &&
        order.containsKey('items') &&
        order.containsKey('status') &&
        order.containsKey('time') &&
        order.containsKey('total') &&
        order['items'] is List;
  }

  /// Validates order update data
  bool _isValidUpdate(Map<String, dynamic> update) {
    return update.containsKey('orderId') && update.containsKey('status');
  }

  /// Validates bill data
  bool _isValidBill(Map<String, dynamic> bill) {
    return bill.containsKey('id') &&
        bill.containsKey('table') &&
        bill.containsKey('amount') &&
        bill.containsKey('status') &&
        bill.containsKey('time');
  }

  /// Processes queued socket events
  void _processEventQueue() async {
    if (_isProcessingQueue || !socket.connected || bloc == null) {
      print('Skipping queue processing: isProcessing=$_isProcessingQueue, connected=${socket.connected}, bloc=${bloc != null}');
      return;
    }
    _isProcessingQueue = true;

    while (_eventQueue.isNotEmpty) {
      final event = _eventQueue.removeAt(0);
      final eventType = event['event'];
      final data = event['data'];

      // Skip redundant orderUpdated events
      if (eventType == 'orderUpdated') {
        final orderId = data['orderId'].toString();
        final status = data['status'];
        final currentOrder = bloc!.state.orders.firstWhere(
          (o) => o['id'].toString() == orderId,
          orElse: () => <String, dynamic>{},
        );
        if (currentOrder.isNotEmpty && currentOrder['status'] == status) {
          print('Skipping redundant orderUpdated for order $orderId, status already $status');
          continue;
        }
      }

      // Trigger BLoC events using the stored BLoC instance
      if (eventType == 'newOrder') {
        bloc!.add(AddNewOrder(data));
      } else if (eventType == 'orderUpdated') {
        bloc!.add(UpdateOrderStatusEvent(data['orderId'].toString(), data['status']));
      } else if (eventType == 'ordersFetched') {
        bloc!.add(RefreshDashboard());
      }

      print('Processing queued event: $eventType, data: $data');
    }

    _isProcessingQueue = false;
  }

  /// Attempts to reconnect with exponential backoff
  void _attemptReconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnect attempts reached. Please check server availability.');
      return;
    }

    final delay = _initialReconnectDelay * pow(2, _reconnectAttempts);
    print('Attempting to reconnect in ${delay.inSeconds} seconds... (Attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)');
    await Future.delayed(delay);
    _reconnectAttempts++;
    connect();
  }

  /// Connects to the socket server
  void connect() {
    if (!socket.connected) {
      socket.connect();
    }
  }

  /// Disconnects from the socket server and cleans up
  void disconnect() {
    socket.disconnect();
    socket.clearListeners();
    _eventQueue.clear();
    _reconnectAttempts = 0;
    print('Socket disconnected and listeners cleared');
  }

  /// Sends a new order to the server
  void placeOrder(Map<String, dynamic> order) {
    if (_isValidOrder(order)) {
      socket.emit('placeOrder', order);
      print('Emitted placeOrder: $order');
    } else {
      print('Invalid order data, not emitting: $order');
    }
  }

  /// Updates the status of an existing order
  void updateOrderStatus(String orderId, String status) {
    socket.emit('updateStatus', {
      'orderId': orderId,
      'status': status,
      'sourceSocketId': socket.id,
    });
    print('Emitted updateOrderStatus: orderId=$orderId, status=$status, sourceSocketId=${socket.id}');
  }

  /// Fetches all orders from the server
  Future<List<Map<String, dynamic>>> fetchOrders() async {
    if (!socket.connected) {
       socket.connect();
    }

    Completer<List<Map<String, dynamic>>> completer = Completer();
    socket.emit('fetchOrders');

    socket.once('ordersFetched', (data) {
      try {
        final orders = List<Map<String, dynamic>>.from(data);
        if (orders.every(_isValidOrder)) {
          _lastKnownOrders = orders; // Update last known orders
          print('Fetched ${orders.length} valid orders');
          completer.complete(orders);
        } else {
          print('Invalid orders data received, returning last known orders: ${_lastKnownOrders.length}');
          completer.complete(_lastKnownOrders);
        }
      } catch (e) {
        print('Error parsing orders: $e');
        completer.complete(_lastKnownOrders); // Return last known orders on error
      }
    });

    // Timeout after 5 seconds
    return await completer.future.timeout(Duration(seconds: 5), onTimeout: () {
      print('Fetch orders timed out, returning last known orders: ${_lastKnownOrders.length}');
      return _lastKnownOrders; // Return last known orders on timeout
    });
  }
/// Fetches all bills from the server
  Future<List<Map<String, dynamic>>> fetchBills() async {
    if (!socket.connected) {
      socket.connect();
    }

    Completer<List<Map<String, dynamic>>> completer = Completer();
    socket.emit('fetchBills');

    socket.once('billsFetched', (data) {
      try {
        final bills = List<Map<String, dynamic>>.from(data);
        print('Fetched ${bills.length} bills');
        completer.complete(bills);
      } catch (e) {
        print('Error parsing bills: $e');
        completer.completeError(e);
      }
    });

    return await completer.future.timeout(Duration(seconds: 5), onTimeout: () {
      print('Fetch bills timed out');
      return [];
    });
  }
void payBill(Map<String, dynamic> bill) {
    socket.emit('payBill', bill);
    print('Emitted payBill: $bill');
  }/// Creates a new bill on the server
  void createBill(Map<String, dynamic> bill) {
    socket.emit('createBill', bill);
    print('Emitted createBill: $bill');
  }
  /// Disposes the socket service
  void dispose() {
    disconnect();
    socket.dispose();
    _eventQueue.clear();
    _reconnectAttempts = 0;
    print('Socket service disposed');
  }
}
