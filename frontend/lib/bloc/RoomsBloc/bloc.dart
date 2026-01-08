import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/apiServicesRoom.dart';
import 'event.dart';
import 'state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final ApiServiceRooms apiService;

  RoomBloc(this.apiService) : super(RoomInitial()) {
    on<LoadRooms>((event, emit) async {
      emit(RoomLoading());
      try {
        final rooms = await apiService.getAllRooms();
        emit(RoomLoaded(rooms));
      } catch (e) {
        emit(RoomError(e.toString()));
      }
    });

    on<DeleteRoomEvent>((event, emit) async {
      try {
        await apiService.deleteRoomById(event.id);
        add(LoadRooms());
      } catch (e) {
        emit(RoomError(e.toString()));
      }
    });
  }
}
