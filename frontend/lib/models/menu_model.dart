class MenuModel {
  final String name;
  final List<String> items;

  MenuModel({required this.name, required this.items});

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
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
