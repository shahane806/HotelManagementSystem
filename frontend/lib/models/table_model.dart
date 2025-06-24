class TableModel {
  final String name;
  final int count;

  TableModel({required this.name, required this.count});

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
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