import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/amenity_model.dart';
import '../../services/apiServicesAminities.dart';
import 'event.dart';
import 'state.dart';

class AmenitiesBloc extends Bloc<AmenitiesEvents, AmenitiesState> {
  AmenitiesBloc() : super(AmenitiesInitial()) {
    on<FetchAmenities>(_onFetchAmenities);
    on<AddAmenities>(_onAddAmenity);
    on<DeleteAmenities>(_onDeleteAmenity);
  }

  final ApiServiceAmenities apiService = ApiServiceAmenities();

  Future<void> _onFetchAmenities(
    FetchAmenities event,
    Emitter<AmenitiesState> emit,
  ) async {
    emit(AmenitiesLoading());
    try {
      final List<AmenityModel> amenities = await apiService.getAmenityModel();
      print("Amenity log : ${amenities}");
      emit(AmenitiesLoaded(amenities));
    } catch (e) {
      emit(AmenitiesError('Failed to load amenities: $e'));
    }
  }

  Future<void> _onAddAmenity(
    AddAmenities event,
    Emitter<AmenitiesState> emit,
  ) async {
    emit(AmenitiesLoading());
    try {
      await apiService.addAmenity(event.amenityItemName);
      final List<AmenityModel> amenities = await apiService.getAmenityModel();
      emit(AmenitiesLoaded(amenities)); // ✅ emit updated list
    } catch (e) {
      emit(AmenitiesError('Failed to add amenity: $e'));
    }
  }

  Future<void> _onDeleteAmenity(
  DeleteAmenities event,
  Emitter<AmenitiesState> emit,
) async {
  emit(AmenitiesLoading());
  try {
   await apiService.deleteAmenity(event.amenityItemName);
   emit(AmenitiesLoading());
    try {
      final List<AmenityModel> amenities = await apiService.getAmenityModel();
      emit(AmenitiesLoaded(amenities));
    } catch (e) {
      emit(AmenitiesError('Failed to load amenities: $e'));
    }
  } catch (e) {
    emit(AmenitiesError("Failed to delete amenity: ${e.toString()}"));
  }
}

}
