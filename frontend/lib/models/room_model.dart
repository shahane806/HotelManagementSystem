import 'package:equatable/equatable.dart';

class RoomModel extends Equatable {
  final int name;
  final String price;
  final bool isAC;

  const RoomModel({required this.name,required this.price, required this.isAC});

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      name: json['name'] as int,
      price: json['price'] as String,
      isAC: json['isAC'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name':name,
      'price': price,
      'isAC': isAC,
    };
  }

  @override
  List<Object?> get props => [name,price,isAC];
}