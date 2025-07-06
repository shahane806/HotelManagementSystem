import 'package:equatable/equatable.dart';
import '../../models/room_model.dart';

abstract class RoomState extends Equatable {
  const RoomState();

  @override
  List<Object?> get props => [];
}

class RoomInitial extends RoomState {
  // Initial state before any room operations are performed
}

class RoomLoading extends RoomState {
  // Loading state used during fetch, add, delete, or update operations
}

class RoomLoaded extends RoomState {
  final List<RoomModel> rooms;

  const RoomLoaded(this.rooms);

  // Used to display the updated list of rooms after fetch, add, delete, or update operations
  @override
  List<Object?> get props => [rooms];
}

class RoomError extends RoomState {
  final String message;

  const RoomError(this.message);

  // Used to display errors from fetch, add, delete, or update operations
  @override
  List<Object?> get props => [message];
}