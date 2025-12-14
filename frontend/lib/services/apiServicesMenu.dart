import 'dart:convert';
import 'package:frontend/app/api_constants.dart';
import 'package:http/http.dart' as http;

import '../app/constants.dart';
import '../models/menu_model.dart';

class ApiServiceMenus {
  final String baseUrl = ApiConstants.url;

  Future<List<MenuModel>> getMenuModel() async {
    try {
      final fullUrl = '$baseUrl/utilities/Menu';
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
          final utilityItems = data[0]['utilityItems'] as List<dynamic>;
          List<MenuModel> menus = utilityItems
              .map((json) => MenuModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return menus;
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load menus: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load menus: $e');
    }
  }

  Future<void> addMenu(String name, String type) async {
    try {
       final token = AppConstants.pref?.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/utilities/Menu/items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'name': name,
          'type': type,
          'items': [],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add menu: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to add menu: $e');
    }
  }

  Future<void> addMenuItem(String menuName, String itemName, String price, String type) async {
    try {
        final token = AppConstants.pref?.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/utilities/Menu/$menuName/items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':'Bearer $token'
        },
        body: jsonEncode({
          'menuitemname': itemName,
          'price': double.parse(price),
          'type': type,
        }),
      );


      if (response.statusCode != 200) {
        throw Exception('Failed to add menu item: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to add menu item: $e');
    }
  }

  Future<void> deleteMenu(String menuName) async {
    try {
       final token = AppConstants.pref?.getString('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/utilities/Menu/$menuName'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':'Bearer $token'
        },
      );


      if (response.statusCode != 200) {
        throw Exception('Failed to delete menu: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete menu: $e');
    }
  }

  Future<void> deleteMenuItem(String menuName, String itemName) async {
    if (menuName.isEmpty) {
      throw Exception('Invalid menu name: $menuName');
    }
    if (itemName.isEmpty) {
      throw Exception('Invalid item name: $itemName');
    }
    try {
       final token = AppConstants.pref?.getString('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/utilities/Menu/$menuName/items/$itemName'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );


      if (response.statusCode != 200) {
        throw Exception('Failed to delete menu item: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete menu item: $e');
    }
  }
}
