import 'dart:convert';
import 'dart:developer' as developer;
import 'package:frontend/app/api_constants.dart';
import 'package:http/http.dart' as http;
import '../models/bill_model.dart';

class Apiservicescheckout {
  static final String baseUrl = ApiConstants.url;

  static Future<List<Map<String, dynamic>>> getAllBills() async {
    try {
      final fullUrl = '$baseUrl/getAllBills';
      developer.log('Attempting GET request to: $fullUrl', name: 'ApiServiceTables');

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      developer.log("Response status: ${response.statusCode}", name: 'ApiServiceTables');
      developer.log("Response body: ${response.body}", name: 'ApiServiceTables');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> bills = data['data'] ?? [];

        developer.log("Parsed bills: $bills", name: 'ApiServiceTables');

        final reversedBills = bills.cast<Map<String, dynamic>>().reversed.toList();

        developer.log("Reversed bills: $reversedBills", name: 'ApiServiceTables');
        return reversedBills;
      } else {
        throw Exception(
            'Failed to load bills: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log("Error in getAllBills: $e", name: 'ApiServiceTables');
      throw Exception('Failed to load bills: $e');
    }
  }

  static Future<void> payBill(Bill obj) async {
    print("Hit payBill: ${obj.toJson()}");
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/payTableBill'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(obj.toJson()),
      );

      if (res.statusCode == 201) {
        print('Success: ${res.body}');
      } else {
        print('Failed with status ${res.statusCode}: ${res.body}');
        throw Exception(
            'Failed to store bill: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print('Error in payBill: $e');
      throw Exception('Failed to store bill: $e');
    }
  }

  static Future<void> updateBillStatus(String billId, String status, String? paymentMethod) async {
    try {
      final fullUrl = '$baseUrl/updateBillStatus';
      developer.log('Attempting POST request to: $fullUrl', name: 'ApiServiceTables');

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'billId': billId,
          'status': status,
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
        }),
      );

      developer.log("Response status: ${response.statusCode}", name: 'ApiServiceTables');
      developer.log("Response body: ${response.body}", name: 'ApiServiceTables');

      if (response.statusCode == 200) {
        print('Bill status updated: ${response.body}');
      } else {
        throw Exception(
            'Failed to update bill status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log("Error in updateBillStatus: $e", name: 'ApiServiceTables');
      throw Exception('Failed to update bill status: $e');
    }
  }
}