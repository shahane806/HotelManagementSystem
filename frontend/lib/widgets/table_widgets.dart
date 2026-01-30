import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../models/menu_model.dart';
import '../models/order_model.dart';

int getTotalPrice(Map<OrderItem, int> order) {
  return order.entries
      .fold(0, (sum, entry) => sum + (entry.key.menuItem.price * entry.value));
}

Color getStatusColor(String status) {
  switch (status) {
    case 'Pending':
      return Colors.red;
    case 'Preparing':
      return Colors.orange;
    case 'Ready':
      return Colors.green;
    case 'Served':
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

List<MenuItem> getMenuItemsFromMenus(List<MenuModel> menus, bool isVegFilter) {
  const categoryEmojis = {
    'Main Course': '🍛',
    'South Indian': '🥞',
    'Beverages': '☕',
    'Desserts': '🍦',
    'Italian': '🍕',
    'Fast Food': '🍔',
    'Juice': '🍹',
    'Starter': '🥗',
    'Chicken 🍗': '🍗',
  };
  final items = menus.expand((menu) {
    developer.log(
        'Filtering menu: ${menu.name}, type: ${menu.type}, items: ${menu.items.length}',
        name: 'TableDashboardScreen');
    return menu.items.where((item) {
      final matchesFilter =
          isVegFilter ? item.type == 'Veg' : item.type == 'Non-Veg';
      developer.log(
          'Item: ${item.menuitemname}, type: ${item.type}, matchesFilter: $matchesFilter',
          name: 'TableDashboardScreen');
      return matchesFilter;
    }).map((entry) {
      final price = int.tryParse(entry.price) ?? 0;
      return MenuItem(
        name: entry.menuitemname,
        price: price,
        category: menu.name,
        image: categoryEmojis[menu.name] ?? '🍽️',
        type: entry.type,
        description: '',
      );
    });
  }).toList();
  developer.log(
      'Filtered items: ${items.length}, filter: ${isVegFilter ? 'Veg' : 'Non-Veg'}',
      name: 'TableDashboardScreen');
  return items;
}
