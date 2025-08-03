import 'package:frontend/app/api_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;

  factory SocketService() {
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
    });

    socket.onDisconnect((_) {
      print('❌ Disconnected from socket server');
    });

    socket.onConnectError((data) {
      print('⚠️ Connect error: $data');
    });

    socket.onError((data) {
      print('❗ Socket error: $data');
    });

    socket.on('newOrder', (data) {
      print('📥 New order received: $data');
    });

    socket.on('orderUpdated', (data) {
      print('📤 Order status updated: $data');
    });
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
  }

  /// Sends a new order to the server
  void placeOrder(Map<String, dynamic> order) {
    socket.emit('placeOrder', order);
  }

  /// Updates the status of an existing order
  void updateOrderStatus(String orderId, String status) {
    socket.emit('updateStatus', {
      'orderId': orderId,
      'status': status,
    });
  }

  /// Disposes the socket service
  void dispose() {
    socket.dispose();
  }
}