import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;

class MenuModel extends Equatable {
  final String name;
  final List<MenuItemModel> items;
  final String type;

  const MenuModel({
    required this.name,
    required this.items,
    required this.type,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? 'Veg';
    final items = (json['items'] as List<dynamic>?)
            ?.map((item) => MenuItemModel.fromJson(item as Map<String, dynamic>, type))
            .toList() ?? [];
    developer.log('Parsed MenuModel: ${json['name']}, type: $type, items: ${items.length}', name: 'MenuModel');
    return MenuModel(
      name: json['name']?.toString() ?? 'Unknown',
      items: items,
      type: type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
      'type': type,
    };
  }

  @override
  List<Object> get props => [name, items, type];
}

class MenuItemModel extends Equatable {
  final String menuitemname;
  final String price;
  final String type;

  const MenuItemModel({
    required this.menuitemname,
    required this.price,
    required this.type,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json, String parentType) {
    final itemName = json['menuitemname']?.toString() ?? 'Unknown Item';
    // Infer Non-Veg type from item name if it contains "chicken" or "biryani"
    final inferredType = itemName.toLowerCase().contains('chicken') || itemName.toLowerCase().contains('biryani')
        ? 'Non-Veg'
        : (json['type']?.toString() ?? parentType);
    developer.log('Parsed MenuItemModel: $itemName, price: ${json['price']}, type: $inferredType', name: 'MenuItemModel');
    return MenuItemModel(
      menuitemname: itemName,
      price: json['price']?.toString() ?? '0',
      type: inferredType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuitemname': menuitemname,
      'price': price,
      'type': type,
    };
  }

  @override
  List<Object> get props => [menuitemname, price, type];
}

class MenuItem extends Equatable {
  final String name;
  final int price;
  final String category;
  final String image;
  final String type;

  const MenuItem({
    required this.name,
    required this.price,
    required this.category,
    required this.image,
    required this.type,
  });

  @override
  List<Object> get props => [name, price, category, image, type];
}
