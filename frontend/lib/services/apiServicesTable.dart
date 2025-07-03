import 'dart:convert';
import 'package:frontend/app/api_constants.dart';
import 'package:http/http.dart' as http;
import '../models/table_model.dart';

class ApiServiceTables {
  final String baseUrl = ApiConstants.url;

  Future<List<TableModel>> getTables() async {
    try {
      final fullUrl = '$baseUrl/utilities/Table';
      print('Attempting GET request to: $fullUrl');

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
          List<TableModel> tables = data
              .map((json) => TableModel.fromJson(json as Map<String, dynamic>))
              .toList();
          print("Parsed tables: ${tables.map((t) => t.utilityName).toList()}");
          return tables;
        } else {
          print("No table data found in response");
          return [];
        }
      } else {
        throw Exception('Failed to load tables: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error in getTables: $e");
      throw Exception('Failed to load tables: $e');
    }
  }

  Future<void> addTableItem(String utilityId, String name, int count) async {
    if (utilityId.isEmpty) {
      throw Exception('Invalid utility ID: $utilityId');
    }
    if (name.isEmpty) {
      throw Exception('Invalid table name: $name');
    }
    if (count <= 0) {
      throw Exception('Invalid seating capacity: $count');
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/utilities/Table/items'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'count': count,
        }),
      );

      print("Add table item response: ${response.statusCode} - ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Failed to add table item: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error in addTableItem: $e");
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
      final response = await http.delete(
        Uri.parse('$baseUrl/utilities/Table/$itemName'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print("Delete table item response: ${response.statusCode} - ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Failed to delete table item: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error in deleteTableItem: $e");
      throw Exception('Failed to delete table item: $e');
    }
  }
}