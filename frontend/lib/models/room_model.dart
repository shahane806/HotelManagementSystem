class RoomModel {
  final String name;
  final bool isAC;

  RoomModel({required this.name, required this.isAC});

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      name: json['name'] as String,
      isAC: json['isAC'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isAC': isAC,
    };
  }
}