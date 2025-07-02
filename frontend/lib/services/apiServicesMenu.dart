import 'dart:convert';
import 'package:frontend/app/api_constants.dart';
import 'package:http/http.dart' as http;

import '../models/menu_model.dart';

class ApiServiceMenus {
  final String baseUrl = ApiConstants.url;

  Future<List<MenuModel>> getMenuModel() async {
    try {
      final fullUrl = '$baseUrl/utilities/Menu';
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
          // The API returns a list with one object, which contains utilityItems (the menus)
          final utilityItems = data[0]['utilityItems'] as List<dynamic>;
          List<MenuModel> menus = utilityItems
              .map((json) => MenuModel.fromJson(json as Map<String, dynamic>))
              .toList();
          print("Parsed menus: ${menus.map((m) => m.name).toList()}");
          return menus;
        } else {
          print("No menu data found in response");
          return [];
        }
      } else {
        throw Exception('Failed to load menus: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error in getMenuModel: $e");
      throw Exception('Failed to load menus: $e');
    }
  }

  Future<void> addMenu(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/utilities/Menu/items'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'items': [],
        }),
      );

      print("Add menu response: ${response.statusCode} - ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Failed to add menu: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error in addMenu: $e");
      throw Exception('Failed to add menu: $e');
    }
  }

  Future<void> addMenuItem(String menuName, String itemName, String price) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/utilities/Menu/$menuName/items'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'menuitemname': itemName, 
        'price': double.parse(price), 
      }),
    );

    print("Add menu item response: ${response.statusCode} - ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Failed to add menu item: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print("Error in addMenuItem: $e");
    throw Exception('Failed to add menu item: $e');
  }
}

  Future<void> deleteMenu(String menuName) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/utilities/Menu/$menuName'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print("Delete menu response: ${response.statusCode} - ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Failed to delete menu: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error in deleteMenu: $e");
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
      final response = await http.delete(
        Uri.parse('$baseUrl/utilities/Menu/$menuName/items/$itemName'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print("Delete menu item response: ${response.statusCode} - ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Failed to delete menu item: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error in deleteMenuItem: $e");
      throw Exception('Failed to delete menu item: $e');
    }
  }
}