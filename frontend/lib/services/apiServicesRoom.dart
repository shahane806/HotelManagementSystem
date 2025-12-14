import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../app/api_constants.dart';
import '../../models/room_model.dart';
import '../app/constants.dart';

class ApiServiceRooms {
  final String baseUrl = ApiConstants.url;

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
}