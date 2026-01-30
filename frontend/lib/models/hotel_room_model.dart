class HotelRoomModel {
  final String id;
  final String roomNo;
  final String type;
  final int capacity;
  final double pricePerNight;
  final int floor;
  final String description;
  final List<String> facilities;
  final List<String> images;
  final String status;
  final double? rating;
  final int? totalReviews;

  HotelRoomModel({
    required this.id,
    required this.roomNo,
    required this.type,
    required this.capacity,
    required this.pricePerNight,
    required this.floor,
    required this.description,
    required this.facilities,
    required this.images,
    this.status = 'available',
    this.rating,
    this.totalReviews,
  });

  /// Safely parses the 'images' field whether it's:
  /// - List<String>
  /// - String (comma-separated: "img1.jpg,img2.jpg")
  /// - null
  static List<String> _parseImages(dynamic imagesJson) {
    if (imagesJson == null) return [];

    // CASE 1: List (from backend)
    if (imagesJson is List) {
      return imagesJson
          .map((img) {
            // If backend sends object { url: "..."}
            if (img is Map && img['url'] != null) {
              return img['url']
                  .toString()
                  .replaceAll('\\', '/'); // VERY IMPORTANT
            }

            // If backend sends plain string
            if (img is String) {
              return img.replaceAll('\\', '/');
            }

            return '';
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // CASE 2: Comma-separated string
    if (imagesJson is String) {
      return imagesJson
          .split(',')
          .map((s) => s.trim().replaceAll('\\', '/'))
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return [];
  }

  /// Safely parses facilities list
  static List<String> _parseFacilities(dynamic facilitiesJson) {
    if (facilitiesJson == null) return [];
    if (facilitiesJson is List) {
      return facilitiesJson
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  factory HotelRoomModel.fromJson(Map<String, dynamic> json) {
    return HotelRoomModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      roomNo: json['roomNo'] as String? ?? '',
      type: json['type'] as String? ?? 'Standard',
      capacity: (json['capacity'] is num)
          ? (json['capacity'] as num).toInt()
          : (json['capacity'] is String)
              ? int.tryParse(json['capacity']) ?? 2
              : 2,
      pricePerNight: (json['pricePerNight'] is num)
          ? (json['pricePerNight'] as num).toDouble()
          : (json['pricePerNight'] is String)
              ? double.tryParse(json['pricePerNight']) ?? 0.0
              : 0.0,
      floor: (json['floor'] is num)
          ? (json['floor'] as num).toInt()
          : (json['floor'] is String)
              ? int.tryParse(json['floor']) ?? 1
              : 1,
      description: json['description'] as String? ?? '',
      facilities: _parseFacilities(json['facilities']),
      images: _parseImages(json['images']),
      status: json['status'] as String? ?? 'available',
      rating: json['rating'] is num
          ? (json['rating'] as num).toDouble()
          : (json['rating'] is String)
              ? double.tryParse(json['rating'])
              : null,
      totalReviews: json['totalReviews'] is num
          ? (json['totalReviews'] as num).toInt()
          : (json['totalReviews'] is String)
              ? int.tryParse(json['totalReviews'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id.isEmpty ? null : id,
      'roomNo': roomNo,
      'type': type,
      'capacity': capacity,
      'pricePerNight': pricePerNight,
      'floor': floor,
      'description': description,
      'facilities': facilities,
      'images': images,
      'status': status,
      'rating': rating,
      'totalReviews': totalReviews,
    }..removeWhere((key, value) => value == null);
  }

  HotelRoomModel copyWith({
    String? id,
    String? roomNo,
    String? type,
    int? capacity,
    double? pricePerNight,
    int? floor,
    String? description,
    List<String>? facilities,
    List<String>? images,
    String? status,
    double? rating,
    int? totalReviews,
  }) {
    return HotelRoomModel(
      id: id ?? this.id,
      roomNo: roomNo ?? this.roomNo,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      floor: floor ?? this.floor,
      description: description ?? this.description,
      facilities: facilities ?? this.facilities,
      images: images ?? this.images,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }

  @override
  String toString() {
    return 'HotelRoomModel(id: $id, roomNo: $roomNo, type: $type, price: $pricePerNight, images: $images)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HotelRoomModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
