import 'dart:async';
import 'dart:math';
import 'package:frontend/app/api_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../bloc/KitchenBloc/bloc.dart';
import '../bloc/KitchenBloc/event.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();

  late IO.Socket socket;
  KitchenDashboardBloc? bloc;

  List<Map<String, dynamic>> _lastKnownOrders = [];
  List<Map<String, dynamic>> _lastKnownBills = [];

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);

  factory SocketService() {
    return _instance;
  }

  /// Attach BLoC (called from UI initState)
  void attachBloc(KitchenDashboardBloc kitchenBloc) {
    bloc = kitchenBloc;
  }

  SocketService._internal() {
    socket = IO.io(
      ApiConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      _reconnectAttempts = 0;
      socket.emit('fetchOrders');
    });

    socket.onDisconnect((_) => _attemptReconnect());
    socket.onConnectError((_) => _attemptReconnect());

    socket.on('newOrder', (data) {
      if (bloc == null) return;
      try {
        bloc!.add(AddNewOrder(Map<String, dynamic>.from(data)));
      } catch (_) {}
    });

    socket.on('orderUpdated', (data) {
      if (bloc == null) return;
      try {
        final update = Map<String, dynamic>.from(data);
        if (!_isValidUpdate(update)) return;

        bloc!.add(
          UpdateOrderStatusEvent(
            update['orderId'].toString(),
            update['status'],
          ),
        );
      } catch (_) {}
    });

    socket.on('ordersFetched', (data) {
      if (bloc == null) return;
      try {
        final orders = List<Map<String, dynamic>>.from(data);
        _lastKnownOrders = orders;
        bloc!.add(RefreshDashboard());
      } catch (_) {
        bloc!.add(RefreshDashboard());
      }
    });

    socket.on('billsFetched', (data) {
      try {
        final bills = List<Map<String, dynamic>>.from(data);
        if (bills.every(_isValidBill)) {
          _lastKnownBills = bills;
        }
      } catch (_) {}
    });
  }

  bool _isValidUpdate(Map<String, dynamic> update) {
    return update.containsKey('orderId') && update.containsKey('status');
  }

  bool _isValidBill(Map<String, dynamic> bill) {
    return bill.containsKey('id') &&
        bill.containsKey('table') &&
        bill.containsKey('amount') &&
        bill.containsKey('status') &&
        bill.containsKey('time');
  }

  void _attemptReconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    final delay =
        _initialReconnectDelay * pow(2, _reconnectAttempts).toInt();
    await Future.delayed(delay);
    _reconnectAttempts++;
    connect();
  }

  void connect() {
    if (!socket.connected) {
      socket.connect();
    }
  }

  void disconnect() {
    socket.disconnect();
    socket.clearListeners();
    _reconnectAttempts = 0;
  }

  void placeOrder(Map<String, dynamic> order) {
    socket.emit('placeOrder', order);
  }

  void updateOrderStatus(String orderId, String status) {
    socket.emit('updateStatus', {
      'orderId': orderId,
      'status': status,
      'sourceSocketId': socket.id,
    });
  }

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    if (!socket.connected) socket.connect();

    final completer = Completer<List<Map<String, dynamic>>>();
    socket.emit('fetchOrders');

    socket.once('ordersFetched', (data) {
      try {
        final orders = List<Map<String, dynamic>>.from(data);
        _lastKnownOrders = orders;
        completer.complete(orders);
      } catch (_) {
        completer.complete(_lastKnownOrders);
      }
    });

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => _lastKnownOrders,
    );
  }

  Future<List<Map<String, dynamic>>> fetchBills() async {
    if (!socket.connected) socket.connect();

    final completer = Completer<List<Map<String, dynamic>>>();
    socket.emit('fetchBills');

    socket.once('billsFetched', (data) {
      try {
        completer.complete(List<Map<String, dynamic>>.from(data));
      } catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => [],
    );
  }

  void payBill(Map<String, dynamic> bill) {
    socket.emit('payBill', bill);
  }

  void createBill(Map<String, dynamic> bill) {
    socket.emit('createBill', bill);
  }

  void dispose() {
    disconnect();
    socket.dispose();
  }
}
