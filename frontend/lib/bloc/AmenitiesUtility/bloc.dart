import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/getAminities.dart';
import 'event.dart';
import 'state.dart';


class AmenitiesBloc extends Bloc<AmenitiesEvents, AmenitiesState> {
  AmenitiesBloc() : super(AmenitiesInitial()) {
    on<FetchAmenities>(_onFetchAmenities);
    on<AddAmenities>(_onAddAmenity);
  }
  ApiService apiService = ApiService();
  Future<void> _onFetchAmenities(FetchAmenities event, Emitter<AmenitiesState> emit) async {
    emit(AmenitiesLoading());
  
    try {
      final amenity = await apiService.getAmenityModel();
      emit(AmenitiesLoaded(amenity));
    } catch (e) {
      emit(AmenitiesError(e.toString()));
    }
  }

  Future<void> _onAddAmenity(AddAmenities event, Emitter<AmenitiesState> emit) async {
    emit(AmenitiesLoading());
    try {
      await apiService.addAmenity(event.amenityItemName);
      final amenity = await apiService.getAmenityModel();
      emit(AmenitiesLoaded(amenity));
    } catch (e) {
      emit(AmenitiesError('Failed to add amenity: $e'));
    }
  }

  // Future<void> _onDeleteAmenity(DeleteAmenities event, Emitter<AmenitiesState> emit) async {
  //   emit(AmenitiesLoading());
  //   try {
  //     await apiService.deleteAmenity(event.amenityItemName);
  //     final amenity = await apiService.getAmenityModel();
  //     emit(AmenitiesLoaded(amenity));
  //   } catch (e) {
  //     emit(AmenitiesError('Failed to delete amenity: $e'));
  //   }
  // }
}