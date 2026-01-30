import 'dart:convert';
import 'package:frontend/app/api_constants.dart';
import 'package:frontend/app/constants.dart';
import 'package:http/http.dart' as http;
import '../models/table_model.dart';

class ApiServiceTables {
  final String baseUrl = ApiConstants.url;

  Future<List<TableModel>> getTables() async {
    try {
      final fullUrl = '$baseUrl/utilities/Table';
      final token = AppConstants.pref?.getString('token');
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          List<TableModel> tables = data
              .map((json) => TableModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return tables;
        } else {
          return [];
        }
      } else {
        throw Exception(
            'Failed to load tables: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load tables: $e');
    }
  }

  Future<void> addTableItem(String name, int count) async {
    if (name.isEmpty) {
      throw Exception('Invalid table name: $name');
    }
    if (count <= 0) {
      throw Exception('Invalid seating capacity: $count');
    }
    try {
      final token = AppConstants.pref?.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/utilities/Table/items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'name': name,
          'count': count,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to add table item: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to add table item: $e');
    }
  }

  Future<void> deleteTableItem(String utilityId, String itemName) async {
    if (utilityId.isEmpty) {
      throw Exception('Invalid utility ID: $utilityId');
    }
    if (itemName.isEmpty) {
      throw Exception('Invalid item name: $itemName');
    }
    try {
      final token = AppConstants.pref?.getString('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/utilities/Table/$itemName'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete table item: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete table item: $e');
    }
  }
}
