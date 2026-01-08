abstract class RoomEvent {}

class LoadRooms extends RoomEvent {}

class DeleteRoomEvent extends RoomEvent {
  final String id;
  DeleteRoomEvent(this.id);
}
