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
  List<Map<String, dynamic>> _lastKnownOrders =
      []; // Cache for last valid orders
  List<Map<String, dynamic>> _lastKnownBills =
      []; // Cache for last valid bills// Cache for last valid orders
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
      _reconnectAttempts =
          0; // Reset reconnect attempts on successful connection
      _processEventQueue();
      // Emit event to fetch initial orders
      socket.emit('fetchOrders');
    });

    socket.onDisconnect((_) {
      _attemptReconnect();
    });

    socket.onConnectError((data) {
      _attemptReconnect();
    });

    socket.onError((data) {
    });

    socket.on('newOrder', (data) {
      try {
        final parsedOrder = Map<String, dynamic>.from(data);
        if (_isValidOrder(parsedOrder)) {
          _eventQueue.add({'event': 'newOrder', 'data': parsedOrder});
          _processEventQueue();
        } else {
        }
      } catch (e) {
      }
    });

    socket.on('orderUpdated', (data) {
      try {
        final update = Map<String, dynamic>.from(data);
        if (_isValidUpdate(update)) {
          _eventQueue.add({'event': 'orderUpdated', 'data': update});
          _processEventQueue();
        } else {
        }
      } catch (e) {
      }
    });

    socket.on('ordersFetched', (data) {
      try {
        final orders = List<Map<String, dynamic>>.from(data);
        if (orders.every(_isValidOrder)) {
          _lastKnownOrders = orders; // Update last known orders
          _eventQueue.add({'event': 'ordersFetched', 'data': orders});
          _processEventQueue();
        } else {
          _eventQueue.add({'event': 'ordersFetched', 'data': _lastKnownOrders});
          _processEventQueue();
        }
      } catch (e) {
        _eventQueue.add({'event': 'ordersFetched', 'data': _lastKnownOrders});
        _processEventQueue();
      }
    });

    
    socket.on('billsFetched', (data) {
      try {
        final bills = List<Map<String, dynamic>>.from(data);
        if (bills.every(_isValidBill)) {
          _lastKnownBills = bills; // Update last known bills
          _eventQueue.add({'event': 'billsFetched', 'data': bills});
          _processEventQueue();
        } else {
          _eventQueue.add({'event': 'billsFetched', 'data': _lastKnownBills});
          _processEventQueue();
        }
      } catch (e) {
        _eventQueue.add({'event': 'billsFetched', 'data': _lastKnownBills});
        _processEventQueue();
      }
    });
    socket.on('billPaid', (data) {
      try {
        // final billData = Map<String, dynamic>.from(data);
        // You can add logic here to handle bill paid event, e.g., notify BLoC
        if (bloc != null) {
          // Assuming you have a BLoC event for bill paid
          // bloc!.add(BillPaidEvent(billData));
        }
      } catch (e) {
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
          continue;
        }
      }

      // Trigger BLoC events using the stored BLoC instance
      if (eventType == 'newOrder') {
        bloc!.add(AddNewOrder(data));
      } else if (eventType == 'orderUpdated') {
        bloc!.add(
            UpdateOrderStatusEvent(data['orderId'].toString(), data['status']));
      } else if (eventType == 'ordersFetched') {
        bloc!.add(RefreshDashboard());
      }
    }

    _isProcessingQueue = false;
  }

  /// Attempts to reconnect with exponential backoff
  void _attemptReconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    final delay = _initialReconnectDelay * pow(2, _reconnectAttempts);
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
  }

  /// Sends a new order to the server
  void placeOrder(Map<String, dynamic> order) {
    if (_isValidOrder(order)) {
      socket.emit('placeOrder', order);
    } else {
    }
  }

  /// Updates the status of an existing order
  void updateOrderStatus(String orderId, String status) {
    socket.emit('updateStatus', {
      'orderId': orderId,
      'status': status,
      'sourceSocketId': socket.id,
    });
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
          completer.complete(orders);
        } else {
          completer.complete(_lastKnownOrders);
        }
      } catch (e) {
        completer
            .complete(_lastKnownOrders); // Return last known orders on error
      }
    });

    // Timeout after 5 seconds
    return await completer.future.timeout(Duration(seconds: 5), onTimeout: () {
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
        completer.complete(bills);
      } catch (e) {
        completer.completeError(e);
      }
    });

    return await completer.future.timeout(Duration(seconds: 5), onTimeout: () {
      return [];
    });
  }

  void payBill(Map<String, dynamic> bill) {
    socket.emit('payBill', bill);
  }

  /// Creates a new bill on the server
  void createBill(Map<String, dynamic> bill) {
    socket.emit('createBill', bill);
  }

  /// Disposes the socket service
  void dispose() {
    disconnect();
    socket.dispose();
    _eventQueue.clear();
    _reconnectAttempts = 0;
  }
}
