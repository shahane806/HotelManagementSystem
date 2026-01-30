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

      developer.log("Response status: ${response.statusCode}",
          name: 'ApiServiceTables');
      developer.log("Response body: ${response.body}",
          name: 'ApiServiceTables');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> bills = data['data'] ?? [];

        developer.log("Parsed bills: $bills", name: 'ApiServiceTables');

        final reversedBills =
            bills.cast<Map<String, dynamic>>().reversed.toList();

        developer.log("Reversed bills: $reversedBills",
            name: 'ApiServiceTables');
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
        print("Analytics Data : ${data}");
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
          'Authorization': 'Bearer $token'
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

  // Custom payment report for selected date range + optional payment method filter
  static Future<Map<String, dynamic>> getPaymentReport({
    required DateTime startDate,
    required DateTime endDate,
    String? paymentMethod, // 'Cash', 'Online' or null for all
  }) async {
    try {
      final token = AppConstants.pref?.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/bills/report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch report');
        }
      } else {
        throw Exception(
            'Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error fetching payment report: $e');
      throw Exception('Failed to fetch payment report: $e');
    }
  }

  static Future<void> updateBillStatus(
    String billId,
    String status,
    String? paymentMethod,
    String? mobile,
    Map<String, dynamic>? transaction, // new param for transaction info
  ) async {
    try {
      final fullUrl = '$baseUrl/updateBillStatus';
      developer.log('Attempting POST request to: $fullUrl',
          name: 'ApiServiceTables');
      final token = AppConstants.pref?.getString('token');
      print("TransactionId : ${transaction?.entries.first.value['txnid']}");
      final body = {
        'billId': billId,
        'status': status,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
        if (transaction != null)
          'transaction': transaction
              .entries.first.value['txnid'], // include transaction in request
      };
      print("Body : ${body}");
      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      developer.log("Response status: ${response.statusCode}",
          name: 'ApiServiceTables');
      developer.log("Response body: ${response.body}",
          name: 'ApiServiceTables');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update bill status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log("Error in updateBillStatus: $e", name: 'ApiServiceTables');
      throw Exception('Failed to update bill status: $e');
    }
  }

  // ───────────────────────────────────────────────
// Generate Payment Report (Custom Date Range + Filters)
// ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> generatePaymentReport({
    required String startDate, // Format: YYYY-MM-DD
    required String endDate, // Format: YYYY-MM-DD
    String? paymentMethod, // Optional: 'Cash' or 'Online'
    String? mobile, // NEW: Optional 10-digit mobile number
  }) async {
    try {
      final token = AppConstants.pref?.getString('token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final fullUrl = '$baseUrl/bills/report';

      // Improved logging - shows all active filters
      developer.log(
        'POST → $fullUrl | '
        'range: $startDate to $endDate | '
        'method: ${paymentMethod ?? "All"} | '
        'mobile: ${mobile ?? "None"}',
        name: 'ApiServiceReport',
      );

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'startDate': startDate,
          'endDate': endDate,
          if (paymentMethod != null && paymentMethod.isNotEmpty)
            'paymentMethod': paymentMethod,
          if (mobile != null && mobile.trim().isNotEmpty && mobile.length >= 10)
            'mobile': mobile.trim(),
        }),
      );

      developer.log('Report Response Status: ${response.statusCode}',
          name: 'ApiServiceReport');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          developer.log(
              'Report generated successfully • ${data['data']?['billCount'] ?? "?"} bills found',
              name: 'ApiServiceReport');
          return data['data'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Failed to generate report');
        }
      } else {
        final errorBody = response.body.length > 300
            ? '${response.body.substring(0, 300)}...'
            : response.body;
        throw Exception('Server error: ${response.statusCode} - $errorBody');
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error generating report: $e',
        name: 'ApiServiceReport',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to generate payment report: $e');
    }
  }
}
