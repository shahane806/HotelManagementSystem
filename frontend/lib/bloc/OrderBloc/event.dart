import 'package:equatable/equatable.dart';
import '../../models/order_model.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class AddOrderItem extends OrdersEvent {
  final OrderItem orderItem;

  const AddOrderItem(this.orderItem);

  @override
  List<Object?> get props => [orderItem];
}

class RemoveOrderItem extends OrdersEvent {
  final OrderItem orderItem;

  const RemoveOrderItem(this.orderItem);

  @override
  List<Object?> get props => [orderItem];
}

class PlaceOrder extends OrdersEvent {
  final String? orderId;
  final String? table;

  const PlaceOrder(this.orderId, this.table);

  @override
  List<Object?> get props => [orderId, table];
}

class FetchRecentOrders extends OrdersEvent {
  const FetchRecentOrders();

  @override
  List<Object?> get props => [];
}

class UpdateOrderStatus extends OrdersEvent {
  final String orderId;
  final String status;

  const UpdateOrderStatus(this.orderId, this.status);

  @override
  List<Object?> get props => [orderId, status];
}

class RemoveRecentOrder extends OrdersEvent {
  final String orderId;
  const RemoveRecentOrder(this.orderId);
  @override
  List<Object> get props => [orderId];
}
