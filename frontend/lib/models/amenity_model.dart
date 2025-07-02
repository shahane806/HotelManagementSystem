class AmenityModel {
  final String name;
  AmenityModel({required this.name});

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    return AmenityModel(name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() => {'name': name};
}