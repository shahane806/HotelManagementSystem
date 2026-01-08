import '../../models/hotel_room_model.dart';

abstract class RoomState {}

class RoomInitial extends RoomState {}

class RoomLoading extends RoomState {}

class RoomLoaded extends RoomState {
  final List<HotelRoomModel> rooms;
  RoomLoaded(this.rooms);
}

class RoomError extends RoomState {
  final String message;
  RoomError(this.message);
}
