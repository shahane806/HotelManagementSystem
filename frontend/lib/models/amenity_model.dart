class AmenityModel {
  final String id;
  final String utilityName;
  final List<dynamic> utilityItems;
  final DateTime createdUtility;
  final DateTime updatedUtility;
  final int v;

  AmenityModel({
    required this.id,
    required this.utilityName,
    required this.utilityItems,
    required this.createdUtility,
    required this.updatedUtility,
    required this.v,
  });

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    return AmenityModel(
      id: json['_id'] as String,
      utilityName: json['utilityName'] as String,
      utilityItems: (json['utilityItems'] as List<dynamic>).map((item) => item['name'] as String).toList(),
      createdUtility: DateTime.parse(json['createdUtility'] as String),
      updatedUtility: DateTime.parse(json['updatedUtility'] as String),
      v: json['__v'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'utilityName': utilityName,
      'utilityItems': utilityItems.map((item) => {'name': item}).toList(),
      'createdUtility': createdUtility.toIso8601String(),
      'updatedUtility': updatedUtility.toIso8601String(),
      '__v': v,
    };
  }
}