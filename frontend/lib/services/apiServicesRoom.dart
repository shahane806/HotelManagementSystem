import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../app/api_constants.dart';
import '../../models/room_model.dart';

class ApiServiceRooms {
  final String baseUrl = ApiConstants.url;

  Future<List<RoomModel>> getRoomModel() async {
    try {
      final fullUrl = '$baseUrl/utilities/Room';
      // print('Attempting GET request to: $fullUrl');

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          // Assuming API returns a list with one object containing utilityItems (rooms)
          final utilityItems = data[0]['utilityItems'] as List<dynamic>;
          List<RoomModel> rooms = utilityItems
              .map((json) => RoomModel.fromJson(json as Map<String, dynamic>))
              .toList();
          print("Parsed rooms: ${rooms.map((r) => r.name).toList()}");
          return rooms;
        } else {
          print("No room data found in response");
          return [];
        }
      } else {
        throw Exception('Failed to load rooms: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error in getRoomModel: $e");
      throw Exception('Failed to load rooms: $e');
    }
  }

  Future<void> addRoom(int name, String price, bool isAC) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/utilities/Room/items'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'price': price,
          'isAC': isAC,
        }),
      );

      print("Add room response: ${response.statusCode} - ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Failed to add room: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error in addRoom: $e");
      throw Exception('Failed to add room: $e');
    }
  }

  Future<void> deleteRoom(int name) async {
    if (name <= 0) {
      throw Exception('Invalid room number: $name');
    }
    try {
      print("DeleteOm: $baseUrl/utilities/Room/$name");
      final response = await http.delete(
        Uri.parse('$baseUrl/utilities/Room/$name'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print("Delete room response: ${response.statusCode} - ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Failed to delete room: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error in deleteRoom: $e");
      throw Exception('Failed to delete room: $e');
    }
  }
}