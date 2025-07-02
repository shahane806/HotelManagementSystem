import 'dart:convert';
import 'package:frontend/app/api_constants.dart';
import 'package:http/http.dart' as http;

import '../models/amenity_model.dart';

class ApiServiceAmenities {
  final String baseUrl = ApiConstants.url; // Replace with your API URL

  Future<List<AmenityModel>> getAmenityModel() async {
    try {
      final fullUrl = '$baseUrl/utilities/Amenity/';
      print('Attempting GET request to: $fullUrl');

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print("response status: ${response.statusCode}");
      print("response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          // Check the structure of each item
          print("Decoded data: $data");

          // If your AmenityModel expects a 'name' field directly, but your API returns
          // utilityItems: [{name: ...}], you need to extract the names from utilityItems.
          List<AmenityModel> amenities = [];

          for (var item in data) {
            if (item['utilityItems'] != null && item['utilityItems'] is List) {
              for (var util in item['utilityItems']) {
                // Assuming AmenityModel has a fromJson expecting a map with 'name'
                amenities.add(AmenityModel.fromJson(util));
              }
            }
          }

          print("Parsed Amenity Models: $amenities");
          return amenities;
        } else {
          throw Exception('No amenity data found');
        }
      } else {
        throw Exception('Failed to load amenities: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load amenities: $e');
    }
  }

  Future<void> addAmenity(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/utilities/Amenity/items'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add amenity: ${response.body}');
    }
  }

  Future<void> deleteAmenity(String name) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/utilities/Amenity/items/$name'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      print("Delete : ${jsonDecode(response.body)}");
      if (response.statusCode != 200) {
        throw Exception('Failed to delete amenity: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete amenity: $e');
    }
  }
}
