import 'dart:convert';
import 'package:frontend/app/api_constants.dart';
import 'package:http/http.dart' as http;
import '../models/amenity_model.dart';

class ApiService {
  final String baseUrl = ApiConstants.url; // Replace with your API URL

  Future<AmenityModel> getAmenityModel() async {
     
    try {
      final response = await http.get(
      Uri.parse('$baseUrl/utilities/Amenity'),
      headers: {
        'Content-Type': 'application/json',
      },
      );
      // Use debugPrint for Flutter apps to ensure output is shown
      // or use print if running in a Dart console app
      print("response status: ${response.statusCode}");
      print("response body: ${response.body}");
   if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        return AmenityModel.fromJson(data[0]);
      } else {
        throw Exception('No amenity data found');
      }
    } else {
      throw Exception('Failed to load amenities: ${response.body}');
    }
    } catch (e) {
        throw Exception('Failed to load amenities: ${e}');
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

  // Future<void> deleteAmenity(String name) async {
  //   final response = await http.delete(
  //     Uri.parse('$baseUrl/utilities/Amenity/items/$name'),
  //     headers: {
  //       'Content-Type': 'application/json',
  //     },
  //   );

  //   if (response.statusCode != 200) {
  //     throw Exception('Failed to delete amenity: ${response.body}');
  //   }
  // }
}