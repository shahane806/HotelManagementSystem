import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/services/apiServicesRoom.dart';

import 'event.dart';
import 'state.dart';

class RoomsBloc extends Bloc<RoomEvents, RoomState> {
  RoomsBloc() : super(RoomInitial()) {
    on<FetchRooms>(_onFetchRooms);
    on<AddRoom>(_onAddRoom);
    on<DeleteRoom>(_onDeleteRoom);
  }
  final ApiServiceRooms apiService = ApiServiceRooms();

  Future<void> _onFetchRooms(FetchRooms event, Emitter<RoomState> emit) async {
    emit(RoomLoading());
    try {
      final rooms = await apiService.getRoomModel();
      emit(RoomLoaded(rooms));
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  Future<void> _onAddRoom(AddRoom event, Emitter<RoomState> emit) async {
    emit(RoomLoading());
    try {
      await apiService.addRoom(event.name, event.price, event.isAC);
      final rooms = await apiService.getRoomModel(); // Refresh the list
      emit(RoomLoaded(rooms));
    } catch (e) {
      emit(RoomError('Failed to add room: $e'));
    }
  }

  Future<void> _onDeleteRoom(DeleteRoom event, Emitter<RoomState> emit) async {
    emit(RoomLoading());
    try {
      await apiService.deleteRoom(event.name);
      final rooms = await apiService.getRoomModel(); // Refresh the list
      emit(RoomLoaded(rooms));
    } catch (e) {
      emit(RoomError('Failed to delete room: $e'));
    }
  }
}
