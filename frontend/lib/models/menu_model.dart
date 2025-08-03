class MenuEntry {
  final String menuitemname;
  final String price;

  MenuEntry({required this.menuitemname, required this.price});

  factory MenuEntry.fromJson(Map<String, dynamic> json) {
    return MenuEntry(
      menuitemname: json['menuitemname'] as String? ?? 'Unnamed Item',
      price: json['price']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuitemname': menuitemname,
      'price': price,
    };
  }
}

class MenuModel {
  final String name;
  final List<MenuEntry> items;

  MenuModel({required this.name, required this.items});

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    // Handle flat structure with name as Map
    if (json.containsKey('name')) {
      String name;
      if (json['name'] is String) {
        name = json['name'] as String? ?? 'Unnamed Menu';
      } else if (json['name'] is Map<String, dynamic>) {
        name = json['name']['value'] as String? ?? 'Unnamed Menu';
      } else {
        name = 'Unnamed Menu';
      }
      return MenuModel(
        name: name,
        items: (json['items'] as List<dynamic>?)
                ?.map((item) => MenuEntry.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
      );
    }
    // Handle nested utilityItems structure
    else if (json.containsKey('utilityItems')) {
      final utilityItems = json['utilityItems'] as List<dynamic>?;
      if (utilityItems != null && utilityItems.isNotEmpty) {
        final firstItem = utilityItems[0] as Map<String, dynamic>;
        String name;
        if (firstItem['name'] is String) {
          name = firstItem['name'] as String? ?? 'Unnamed Menu';
        } else if (firstItem['name'] is Map<String, dynamic>) {
          name = firstItem['name']['value'] as String? ?? 'Unnamed Menu';
        } else {
          name = 'Unnamed Menu';
        }
        return MenuModel(
          name: name,
          items: (firstItem['items'] as List<dynamic>?)
                  ?.map((item) => MenuEntry.fromJson(item as Map<String, dynamic>))
                  .toList() ??
              [],
        );
      }
    }
    return MenuModel(name: 'Unnamed Menu', items: []);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class MenuItem {
  final String name;
  final int price;
  final String category;
  final String image;

  MenuItem({
    required this.name,
    required this.price,
    required this.category,
    required this.image,
  });

  @override
  bool operator ==(Object other) =>
      other is MenuItem && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    return 'MenuItem(name: $name, price: $price, category: $category, image: $image)';
  }
}

