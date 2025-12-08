
import 'user_model.dart';
import 'order_model.dart';
class Bill {
  final String billId;
  final String table;
  // final UserModel user;
  final List<Order> orders;
  final double totalAmount;
  final bool isGstApplied;

  Bill({
    required this.billId,
    required this.table,
    // required this.user,
    required this.orders,
    required this.totalAmount,
    required this.isGstApplied,
  });

  Map<String, dynamic> toJson() => {
        'billId': billId,
        'table': table,
        // 'user': user.toJson(), // ✅ convert properly
        'orders': orders.map((e) => e.toJson()).toList(), // ✅ convert list
        'totalAmount': totalAmount,
        'isGstApplied': isGstApplied,
      };
}
