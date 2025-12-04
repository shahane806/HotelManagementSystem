import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/services/apiServicesStaff.dart';

import 'event.dart';
import 'state.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {

  StaffBloc() : super(StaffInitial()) {
    on<FetchStaff>(_onFetchStaff);
    on<AddStaff>(_onAddStaff);
    on<UpdateStaff>(_onUpdateStaff);
    on<DeleteStaff>(_onDeleteStaff);
  }
  StaffApiService apiService = StaffApiService();
  Future<void> _onFetchStaff(FetchStaff event, Emitter<StaffState> emit) async {
    emit(StaffLoading());
    try {
      final staff = await apiService.getAllStaff();
      emit(StaffLoaded(staff));
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  Future<void> _onAddStaff(AddStaff event, Emitter<StaffState> emit) async {
    emit(StaffLoading());
    try {
      await apiService.createStaff(event.Staff);
      final staff = await apiService.getAllStaff();
      emit(StaffLoaded(staff));
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  Future<void> _onUpdateStaff(UpdateStaff event, Emitter<StaffState> emit) async {
    emit(StaffLoading());
    try {
      await apiService.updateStaff(event.Staff);
      final staff = await apiService.getAllStaff();
      emit(StaffLoaded(staff));
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  Future<void> _onDeleteStaff(DeleteStaff event, Emitter<StaffState> emit) async {
    emit(StaffLoading());
    try {
      await apiService.deleteStaff(event.userId);
      final staff = await apiService.getAllStaff();
      emit(StaffLoaded(staff));
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }
}