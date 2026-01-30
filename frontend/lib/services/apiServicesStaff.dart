import 'dart:convert';

import '../app/api_constants.dart';
import '../app/constants.dart';
import '../models/user_model.dart';
import 'package:http/http.dart' as http;

class StaffApiService {
  static final String _baseUrl = "${ApiConstants.url}/staff";
  // Fetch all staff
  Future<List<UserModel>> getAllStaff() async {
    try {
      final token = AppConstants.pref?.getString('token');
      final response = await http.get(Uri.parse(_baseUrl), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load Staffs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching Staffs: $e');
    }
  }

  // Get Single Staff using ID
  Future<UserModel> getStaffById(String staffId) async {
    try {
      final token = AppConstants.pref?.getString('token');
      final response = await http.post(Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: jsonEncode({
            "staffId": staffId,
          }));
      if (response.statusCode == 200) {
        final UserModel user = jsonDecode(response.body);
        return user;
      } else {
        throw Exception('Failed to load Staff : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching Staff : $e');
    }
  }

  // Create a new Staff
  Future<UserModel> createStaff(UserModel staff) async {
    print("Staff: ${staff.toJson()}");
    try {
      final token = AppConstants.pref?.getString('token');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(staff.toJson()),
      );
      if (response.statusCode == 201) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create Staff: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating Staff: $e');
    }
  }

  // Update a Staff
  Future<UserModel> updateStaff(UserModel staff) async {
    try {
      final token = AppConstants.pref?.getString('token');
      final response = await http.put(
        Uri.parse('$_baseUrl/${staff.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(staff.toJson()),
      );
      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update Staff: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating Staff: $e');
    }
  }

  // Delete a Staff
  Future<void> deleteStaff(String userId) async {
    try {
      final token = AppConstants.pref?.getString('token');
      final response = await http.delete(Uri.parse('$_baseUrl/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          });
      if (response.statusCode != 200) {
        throw Exception('Failed to delete Staff: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting Staff: $e');
    }
  }
}
