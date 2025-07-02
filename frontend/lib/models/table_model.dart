class TableItem {
  final String name;
  final int count;

  TableItem({required this.name, required this.count});

  factory TableItem.fromJson(Map<String, dynamic> json) {
    return TableItem(
      name: json['name'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
    };
  }
}

class TableModel {
  final String id;
  final String utilityName;
  final List<TableItem> utilityItems;
  final DateTime createdUtility;
  final DateTime updatedUtility;
  final int v;

  TableModel({
    required this.id,
    required this.utilityName,
    required this.utilityItems,
    required this.createdUtility,
    required this.updatedUtility,
    required this.v,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['_id'] as String,
      utilityName: json['utilityName'] as String,
      utilityItems: (json['utilityItems'] as List)
          .map((item) => TableItem.fromJson(item as Map<String, dynamic>))
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