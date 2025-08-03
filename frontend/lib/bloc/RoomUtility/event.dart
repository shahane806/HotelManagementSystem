import 'package:equatable/equatable.dart';

abstract class RoomEvents extends Equatable {
  const RoomEvents();
  @override
  List<Object?> get props => [];
}

class FetchRooms extends RoomEvents {}

class AddRoom extends RoomEvents {
  final int name;
  final String price;
  final bool isAC;
  const AddRoom(this.name, this.price, this.isAC);
  @override
  List<Object?> get props => [name, price, isAC];
}

class DeleteRoom extends RoomEvents {
  final int name;
  const DeleteRoom(this.name);
  @override
  List<Object?> get props => [name];
}