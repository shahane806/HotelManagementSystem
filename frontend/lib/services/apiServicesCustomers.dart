import 'package:frontend/app/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app/constants.dart';
import '../models/user_model.dart';

class CustomerApiService {
  static final String _baseUrl = "${ApiConstants.url}/customers";

  // Fetch all customers
  Future<List<UserModel>> getAllCustomers() async {
    try {
       final token = AppConstants.pref?.getString('token');
      final response = await http.get(Uri.parse(_baseUrl),headers: {'Content-type':'application/json','Authorization':'Bearer $token'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load customers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching customers: $e');
    }
  }
  // Get Single Customer using ID
  Future<UserModel> getCustomerById(String customerID) async{
    try{
       final token = AppConstants.pref?.getString('token');
      final response = await http.post(Uri.parse(_baseUrl),
      headers: {
        'Content-Type':'application/json',
        'Authorization':'Bearer $token'
      },
      body: jsonEncode({
        "CustomerId" : customerID,
      }));
      if(response.statusCode == 200){
        final UserModel user = jsonDecode(response.body);
        return user;
      }else{
        throw Exception('Failed to load customer : ${response.statusCode}');
      }
    }catch(e){
      throw Exception('Error fetching customer : $e');
    }
  }
  // Create a new customer
  Future<UserModel> createCustomer(UserModel customer) async {
    try {
       final token = AppConstants.pref?.getString('token');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json','Authorization':'Bearer $token'},
        body: jsonEncode(customer.toJson()),
      );
      if (response.statusCode == 201) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create customer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating customer: $e');
    }
  }

  // Update a customer
  Future<UserModel> updateCustomer(UserModel customer) async {
    try {
       final token = AppConstants.pref?.getString('token');
      final response = await http.put(
        Uri.parse('$_baseUrl/${customer.id}'),
        headers: {'Content-Type': 'application/json','Authorization':'Bearer $token'},
        body: jsonEncode(customer.toJson()),
      );
      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update customer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating customer: $e');
    }
  }

  // Delete a customer
  Future<void> deleteCustomer(String userId) async {
    try {
       final token = AppConstants.pref?.getString('token');
      final response = await http.delete(Uri.parse('$_baseUrl/$userId'),headers: {'Content-Type':'application/json','Authorization':'Bearer $token'});
      if (response.statusCode != 200) {
        throw Exception('Failed to delete customer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting customer: $e');
    }
  }

}