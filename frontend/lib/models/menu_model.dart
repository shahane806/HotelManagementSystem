class MenuModel {
  final String id;
  final String utilityName;
  final List<MenuItem> utilityItems;
  final DateTime createdUtility;
  final DateTime updatedUtility;
  final int v;

  MenuModel({
    required this.id,
    required this.utilityName,
    required this.utilityItems,
    required this.createdUtility,
    required this.updatedUtility,
    required this.v,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['_id'] as String,
      utilityName: json['utilityName'] as String,
      utilityItems: (json['utilityItems'] as List)
          .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdUtility: DateTime.parse(json['createdUtility'] as String),
      updatedUtility: DateTime.parse(json['updatedUtility'] as String),
      v: json['__v'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'utilityName': utilityName,
      'utilityItems': utilityItems.map((item) => item.toJson()).toList(),
      'createdUtility': createdUtility.toIso8601String(),
      'updatedUtility': updatedUtility.toIso8601String(),
      '__v': v,
    };
  }
}

class MenuItem {
  final String name;
  final List<String> items;

  MenuItem({
    required this.name,
    required this.items,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      name: json['name'] as String,
      items: List<String>.from(json['items'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items,
    };
  }
}
