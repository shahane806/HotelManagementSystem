import 'dart:convert';
import 'package:http/http.dart' as http;

import '../app/api_constants.dart';
import '../models/menu_model.dart';

class ApiServicesMenu{
  final String baseUrl = ApiConstants.url; // Replace with your API URL
  Future<List<MenuModel>> getMenuModel() async {
  final fullUrl = '$baseUrl/utilities/Menu/';
  final response = await http.get(Uri.parse(fullUrl), headers: {
    'Content-Type': 'application/json',
  });
  print("Response Om : ${jsonDecode(response.body)}");
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    List<MenuModel> menus = data.map((json) => MenuModel.fromJson(json)).toList();
          return menus;
  } else {
    throw Exception('Failed to load menu: ${response.body}');
  }
}

Future<void> addMenuItem(String name) async {
  final response = await http.post(
    Uri.parse('$baseUrl/utilities/Menu/items'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'name': name}),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to add menu item: ${response.body}');
  }
}

Future<void> deleteMenuItem(String name) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/utilities/Menu/items/$name'),
    headers: {'Content-Type': 'application/json'},
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to delete menu item: ${response.body}');
  }
}
}