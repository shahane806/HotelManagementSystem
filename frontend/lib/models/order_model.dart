import 'menu_model.dart';


class Order {
  final String id;
  final String table;
  final Map<OrderItem, int> items;
  final int total;
  final DateTime timestamp;
  final String status;

  Order({
    required this.id,
    required this.table,
    required this.items,
    required this.total,
    required this.timestamp,
    this.status = 'Pending',
  });

  Order copyWith({
    String? id,
    String? table,
    Map<OrderItem, int>? items,
    int? total,
    DateTime? timestamp,
    String? status,
  }) {
    return Order(
      id: id ?? this.id,
      table: table ?? this.table,
      items: items ?? this.items,
      total: total ?? this.total,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Order &&
      id == other.id &&
      table == other.table &&
      total == other.total &&
      timestamp == other.timestamp &&
      status == other.status &&
      _mapEquals(items, other.items);

  @override
  int get hashCode =>
      Object.hash(id, table, total, timestamp, status, items.length);

  bool _mapEquals(Map<OrderItem, int> a, Map<OrderItem, int> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }

  @override
  String toString() {
    final itemsStr = items.entries
        .map((e) => '${e.key} x${e.value}')
        .join(', ');
    return 'Order(id: $id, table: $table, total: $total, status: $status, timestamp: $timestamp, items: [$itemsStr])';
  }
}
class OrderItem {
  final MenuItem menuItem;
  final String customization;

  OrderItem({
    required this.menuItem,
    required this.customization,
  });

  @override
  bool operator ==(Object other) =>
      other is OrderItem &&
      menuItem == other.menuItem &&
      customization == other.customization;

  @override
  int get hashCode => Object.hash(menuItem, customization);

  @override
  String toString() {
    return 'OrderItem(menuItem: ${menuItem.name}, customization: $customization)';
  }
}
