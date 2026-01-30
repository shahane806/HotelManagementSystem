import 'package:equatable/equatable.dart';

abstract class AmenitiesEvents extends Equatable {
  const AmenitiesEvents();

  @override
  List<Object?> get props => [];
}

class FetchAmenities extends AmenitiesEvents {}

class AddAmenities extends AmenitiesEvents {
  final String amenityItemName;

  const AddAmenities(this.amenityItemName);

  @override
  List<Object?> get props => [amenityItemName];
}

class DeleteAmenities extends AmenitiesEvents {
  final String amenityItemName;

  const DeleteAmenities(this.amenityItemName);

  @override
  List<Object?> get props => [amenityItemName];
}
