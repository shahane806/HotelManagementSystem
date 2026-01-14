import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../app/api_constants.dart';
import '../../models/room_model.dart';
import '../app/constants.dart';
import '../models/hotel_room_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class ApiServiceRooms {
  final String baseUrl = ApiConstants.url;

  Map<String, String> _headers() {
    final token = AppConstants.pref?.getString('token');
    return {
      'Authorization': 'Bearer $token',
    };
  }

  
  Future<List<RoomModel>> getRoomModel() async {
    try {
      final fullUrl = '$baseUrl/utilities/Room';
      final token = AppConstants.pref?.getString('token');
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          // Assuming API returns a list with one object containing utilityItems (rooms)
          final utilityItems = data[0]['utilityItems'] as List<dynamic>;
          List<RoomModel> rooms = utilityItems
              .map((json) => RoomModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return rooms;
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load rooms: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load rooms: $e');
    }
  }

  Future<void> addRoom(int name, String price, bool isAC) async {
    try {
       final token = AppConstants.pref?.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/utilities/Room/items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':'Bearer $token'
        },
        body: jsonEncode({
          'name': name,
          'price': price,
          'isAC': isAC,
        }),
      );


      if (response.statusCode != 200) {
        throw Exception('Failed to add room: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to add room: $e');
    }
  }

  Future<void> deleteRoom(int name) async {
    if (name <= 0) {
      throw Exception('Invalid room number: $name');
    }
    try {
       final token = AppConstants.pref?.getString('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/utilities/Room/$name'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':'Bearer $token'
        },
      );


      if (response.statusCode != 200) {
        throw Exception('Failed to delete room: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }

  
// =======================
  // GET ALL ROOMS
  // =======================
 Future<List<HotelRoomModel>> getAllRooms() async {
  final response = await http.get(
    Uri.parse('$baseUrl/GetAllRooms'),
    headers: _headers(),
  );

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    final List rooms = body['rooms'];
    return rooms.map((e) => HotelRoomModel.fromJson(e)).toList();
  } else {
    throw Exception(response.body);
  }
}


  // =======================
  // GET ROOM BY ID
  // =======================
  Future<RoomModel> getRoomById(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/GetRoomById/$id'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      return RoomModel.fromJson(jsonDecode(response.body)['room']);
    } else {
      throw Exception(response.body);
    }
  }


  // =======================
  // CREATE ROOM (MULTI IMAGE)
  // =======================
  Future<void> createRoom({
    required String roomNo,
    required String type,
    required int capacity,
    required double pricePerNight,
    required int floor,
    required String description,
    required List<String> facilities,
    required List<dynamic> images,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/roomCreateWithMultipleImages'),
    );

    request.headers.addAll(_headers());

    request.fields.addAll({
      'roomNo': roomNo,
      'type': type,
      'capacity': capacity.toString(),
      'pricePerNight': pricePerNight.toString(),
      'floor': floor.toString(),
      'description': description,
      'facilities': facilities.join(','),
    });
for (var img in images) {
  if (kIsWeb) {
    final bytes = await img.readAsBytes(); // ✅ correct

    request.files.add(
      http.MultipartFile.fromBytes(
        'images',
        bytes,
        filename: img.name,
      ),
    );
  } else {
    request.files.add(
      await http.MultipartFile.fromPath(
        'images',
        img.path,
      ),
    );
  }
}


    final response = await request.send();
    if (response.statusCode != 201) {
      throw Exception('Failed to create room');
    }
  }

  // =======================
  // UPDATE ROOM
  // =======================
  Future<void> updateRoom({
    required String id,
    String? roomNo,
    String? type,
    int? capacity,
    double? price,
    int? floor,
    String? description,
    List<dynamic>? images,
  }) async {
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/UpdateRoomById/$id'),
    );

    request.headers.addAll(_headers());

    if (roomNo != null) request.fields['roomNo'] = roomNo;
    if (type != null) request.fields['type'] = type;
    if (capacity != null) request.fields['capacity'] = capacity.toString();
    if (price != null) request.fields['pricePerNight'] = price.toString();
    if (floor != null) request.fields['floor'] = floor.toString();
    if (description != null) request.fields['description'] = description;

    if (images != null) {
      for (var img in images) {
        request.files.add(
          await http.MultipartFile.fromPath('images', img.path),
        );
      }
    }

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to update room');
    }
  }

  // =======================
  // UPDATE ROOM STATUS
  // =======================
  Future<void> updateRoomStatus(String id, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/UpdateRoomByStatusById/$id/status'),
      headers: {
        ..._headers(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update room status');
    }
  }

  // =======================
  // DELETE ROOM
  // =======================
  Future<void> deleteRoomById(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/DeleteRoomById/$id'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete room');
    }
  }
  
}