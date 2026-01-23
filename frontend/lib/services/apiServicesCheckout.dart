import 'dart:convert';
import 'dart:developer' as developer;
import 'package:frontend/app/api_constants.dart';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import '../models/bill_model.dart';

class Apiservicescheckout {
  static final String baseUrl = ApiConstants.url;

  static Future<List<Map<String, dynamic>>> getAllBills() async {
    try {
        final token = AppConstants.pref?.getString('token');
      final fullUrl = '$baseUrl/getAllBills';
      // developer.log('Attempting GET request to: $fullUrl', name: 'ApiServiceTables');

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
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
static Future<Map<String, dynamic>> getAnalytics() async {
  try {
     final token = AppConstants.pref?.getString('token');
    final response = await http.get(
      Uri.parse('${baseUrl}/bills/analytics'),
      headers: {
        'Content-Type': 'application/json',
         'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch analytics');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching analytics: $e');
  }
}
  static Future<void> payBill(Bill obj) async {
    print("Helo");
    try {
       final token = AppConstants.pref?.getString('token');
       print("token : ${token}");
      final res = await http.post(
        Uri.parse('$baseUrl/payTableBill'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':'Bearer $token'
        },
        body: jsonEncode(obj.toJson()),
      );

      if (res.statusCode == 201) {
        print("Bill Paid");
      } else {
        throw Exception(
            'Failed to store bill: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      throw Exception('Failed to store bill: $e');
    }
  }

  static Future<void> updateBillStatus(String billId, String status, String? paymentMethod,String? mobile,) async {
    try {
      final fullUrl = '$baseUrl/updateBillStatus';
      developer.log('Attempting POST request to: $fullUrl', name: 'ApiServiceTables');
      final token = AppConstants.pref?.getString('token');
      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':'Bearer $token'
        },
        body: jsonEncode({
          'billId': billId,
          'status': status,
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
          if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
        }),
      );

      developer.log("Response status: ${response.statusCode}", name: 'ApiServiceTables');
      developer.log("Response body: ${response.body}", name: 'ApiServiceTables');

      if (response.statusCode == 200) {
      } else {
        throw Exception(
            'Failed to update bill status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log("Error in updateBillStatus: $e", name: 'ApiServiceTables');
      throw Exception('Failed to update bill status: $e');
    }
  }

  // ───────────────────────────────────────────────
  // Generate Payment Report (Custom Date Range)
  // ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> generatePaymentReport({
    required String startDate, // Format: YYYY-MM-DD
    required String endDate,   // Format: YYYY-MM-DD
    String? paymentMethod,     // Optional: 'Cash' or 'Online'
  }) async {
    try {
      final token = AppConstants.pref?.getString('token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final fullUrl = '$baseUrl/bills/report';
      developer.log('POST → $fullUrl (range: $startDate to $endDate)', name: 'ApiServiceReport');

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'startDate': startDate,
          'endDate': endDate,
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
        }),
      );

      developer.log('Report Status: ${response.statusCode}', name: 'ApiServiceReport');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          developer.log('Report generated successfully', name: 'ApiServiceReport');
          return data['data'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Failed to generate report');
        }
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error generating report: $e', name: 'ApiServiceReport');
      throw Exception('Failed to generate payment report: $e');
    }
  }
}