import 'package:equatable/equatable.dart';
import '../../models/amenity_model.dart';

abstract class AmenitiesState extends Equatable {
  const AmenitiesState();

  @override
  List<Object?> get props => [];
}

class AmenitiesInitial extends AmenitiesState {}

class AmenitiesLoading extends AmenitiesState {}

class AmenitiesLoaded extends AmenitiesState {
  final List<AmenityModel> amenities;

  const AmenitiesLoaded(this.amenities);

  @override
  List<Object?> get props => [amenities];
}

class AmenitiesError extends AmenitiesState {
  final String message;

  const AmenitiesError(this.message);

  @override
  List<Object?> get props => [message];
}

