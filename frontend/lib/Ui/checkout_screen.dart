import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/services/socketService.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:developer' as developer;
import '../app/constants.dart';
import '../bloc/BillBloc/bloc.dart';
import '../bloc/BillBloc/event.dart';
import '../bloc/BillBloc/state.dart';
import '../services/apiServicesCheckout.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Map<String, List<Map<String, dynamic>>> _groupedBills = {};
  Map<String, double> _tableTotals = {};
  double _grandTotal = 0.0;
  bool _isLoading = true;
  final bool _isGstApplied = true;
  final Map<String, bool> _processingBills = {};
  final Map<String, TextEditingController> _mobileControllers = {};
  final Map<String, String?> _selectedPaymentMethods = {};
  late SocketService socketService;

  @override
  void initState() {
    super.initState();
    socketService = SocketService();
    socketService.connect();
    socketService.socket.on('newBill', _onNewBill);
    socketService.socket.on('billPaid', _onBillPaid);
    socketService.socket.on('orderUpdated', _onOrderUpdated);
    socketService.socket.on('error', _onError);
    context.read<BillBloc>().add(FetchBills());
    developer.log('CheckoutScreen initialized, fetching bills',
        name: 'CheckoutScreen');
  }

  @override
  void dispose() {
    socketService.socket.off('newBill', _onNewBill);
    socketService.socket.off('billPaid', _onBillPaid);
    socketService.socket.off('orderUpdated', _onOrderUpdated);
    socketService.socket.off('error', _onError);
    socketService.disconnect();
    _mobileControllers.forEach((_, controller) => controller.dispose());
    developer.log('CheckoutScreen disposed', name: 'CheckoutScreen');
    super.dispose();
  }

  void _onNewBill(dynamic data) {
    developer.log('New bill received: $data', name: 'CheckoutScreen');
    context.read<BillBloc>().add(AddBill(Map<String, dynamic>.from(data)));
    context.read<BillBloc>().add(FetchBills());
  }

  void _onBillPaid(dynamic data) {
    developer.log('Bill paid: $data', name: 'CheckoutScreen');
    final billId = data['billId'] as String?;
    if (billId != null && mounted) {
      context.read<BillBloc>().add(UpdateBill(
            billId,
            data['status'] ?? 'Paid',
            paymentMethod: data['paymentMethod'],
          ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful for bill $billId!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _processingBills[billId] = false;
      });
      context.read<BillBloc>().add(FetchBills());
    }
  }

  void _onOrderUpdated(dynamic data) {
    developer.log('Order updated: $data', name: 'CheckoutScreen');
    context.read<BillBloc>().add(FetchBills());
  }

  void _onError(dynamic data) {
    developer.log('Socket error received: $data', name: 'CheckoutScreen');
    final message = data['message'] as String? ?? 'Unknown error';
    final billId = data['billId'] as String?;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (billId != null) {
        setState(() {
          _processingBills[billId] = false;
        });
      }
    }
  }

  void _handlePayment(String billId, String paymentMethod) async {
    if (_mobileControllers[billId] == null ||
        _mobileControllers[billId]!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a mobile number for bill $billId'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final mobile = _mobileControllers[billId]!.text;
    if (!_isValidMobile(mobile)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid mobile number for bill $billId'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _processingBills[billId] = true;
      _selectedPaymentMethods[billId] = paymentMethod;
    });
    final bill = _groupedBills.values
        .expand((bills) => bills)
        .firstWhere((b) => b['billId'] == billId);
    final table = bill['table'] as String;
    final totalAmount = (bill['totalAmount'] as num).toDouble();
    final billData = {
      'billId': billId ?? 'Unknown',
      'table': table ?? 'Unknown',
      'totalAmount': totalAmount ?? 0.0,
      'orders': bill['orders'] as List<dynamic>? ?? [],
      'paymentMethod': paymentMethod ?? 'Unknown',
      'mobile': mobile ?? 'N/A',
      'user': bill['user'] ?? {},
      'isGstApplied': bill['isGstApplied'] as bool? ?? false,
      'status': 'Paid',
    };
    try {
      await Apiservicescheckout.updateBillStatus(billId, 'Paid', paymentMethod);
      socketService.payBill(billData);
      developer.log('Payment initiated for bill $billId, method $paymentMethod',
          name: 'CheckoutScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Payment successful for bill $billId via $paymentMethod'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context
            .read<BillBloc>()
            .add(UpdateBill(billId, 'Paid', paymentMethod: paymentMethod));
        // Generate the pdf of the bill here
        final response = {
          'payuResponse': {
            'mode': paymentMethod ?? 'Unknown',
            'txnid': billId ??
                'TXN${Random().nextInt(1000000).toString().padLeft(6, '0')}',
            'status': 'success'
          }
        };
        await generateReceiptPdf(response, bill['orders'] as List<dynamic>,
            bill['user'], bill['isGstApplied'] as bool);
        context.read<BillBloc>().add(FetchBills());
      }
    } catch (e) {
      developer.log('Error during payment for bill $billId: $e',
          name: 'CheckoutScreen');
      if (mounted) {
        setState(() {
          _processingBills[billId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed for bill $billId. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Sanitize text for plain text output
  String _sanitizeText(dynamic input) {
    final String inputString = input?.toString() ?? '';
    return inputString
        .replaceAll('&', 'and')
        .replaceAll('%', 'percent')
        .replaceAll('\$', 'INR')
        .replaceAll('#', 'No.')
        .replaceAll('_', ' ')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll('~', '')
        .replaceAll('^', '')
        .replaceAll('\\', '');
  }

  // ========================================================
  // 1. Build PDF Document (shared for Web & Mobile)
  // ========================================================
  Future<pw.Document> _buildPdfDocument(
    dynamic response,
    List<dynamic> orders,
    dynamic user,
    bool isGstApplied,
  ) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    final safeOrders = orders.where((order) => order != null).toList();
    final double totalPrice = safeOrders.fold(
      0.0,
      (sum, order) =>
          sum +
          ((order is Map && order['total'] is num)
              ? order['total'].toDouble()
              : 0.0),
    );
    final double gstAmount =
        isGstApplied ? totalPrice * (AppConstants.gstRate ?? 0.0) : 0.0;
    final double total = totalPrice + gstAmount;

    final Map<String, String> paymentMethodMap = {
      'UPI': 'UPI',
      'DYNAMIC_QR': 'Dynamic QR',
      'CHALLAN': 'Challan',
      'ENACH': 'eNACH',
      'EFTNET': 'NEFT/RTGS',
      'PAYTM': 'Paytm',
      'PHONEPE': 'PhonePe',
      'AMAZONPAY': 'Amazon Pay',
      'FREECHARGE': 'FreeCharge',
      'JIOMONEY': 'JioMoney',
      'OLAMONEY': 'Ola Money',
      'AIRTELMONEY': 'Airtel Money',
      'PAYZAPP': 'PayZapp',
      'CC': 'Credit Card',
      'DC': 'Debit Card',
      'MASTERCARD': 'MasterCard',
      'VISA': 'Visa',
      'VISA_ELECTRON': 'Visa Electron',
      'RUPAY': 'RuPay',
      'AMEX': 'American Express',
      'DINERS': 'Diners Club',
      'MAESTRO': 'Maestro',
      'NB': 'Net Banking',
      'EMI': 'EMI',
      'EMI_DC': 'Debit Card EMI',
      'EMI_CARDLESS': 'Cardless EMI',
      'LAZYPAY': 'LazyPay',
      'OLA_POSTPAID': 'Ola Postpaid',
      'PAYPAL': 'PayPal',
      'PLUXEE': 'Pluxee (Sodexo Meal Card)',
      'WALLET': 'Wallet',
      'CASH': 'Cash',
      'Cash': 'Cash',
      'Online': 'Online'
    };

    final payuResponse =
        response is Map && response.containsKey('payuResponse')
            ? response['payuResponse']
            : "Unknown";
    String paymentMethod = 'Unknown';
    if (payuResponse != null) {
      if (payuResponse is String) {
        try {
          final decoded = jsonDecode(payuResponse) as Map;
          paymentMethod =
              paymentMethodMap[decoded['mode']?.toString()] ?? 'Unknown';
        } catch (e) {
          developer.log('Error decoding payuResponse string: $e',
              name: 'CheckoutScreen');
        }
      } else if (payuResponse is Map) {
        paymentMethod =
            paymentMethodMap[payuResponse['mode']?.toString()] ?? 'Unknown';
      }
    }

    final String transactionId =
        payuResponse is Map && payuResponse['txnid'] is String
            ? payuResponse['txnid']
            : 'TXN${Random().nextInt(1000000).toString().padLeft(6, '0')}';
    final String paymentStatus =
        payuResponse is Map && payuResponse['status'] is String
            ? payuResponse['status'].toUpperCase()
            : 'SUCCESS';
    final String date = DateTime.now().toString().split(' ').first;

    final String userName = user is Map && user['fullName'] != null
        ? _sanitizeText(user['fullName'])
        : 'Unknown User';
    final String userMobile = user is Map && user['mobile'] != null
        ? _sanitizeText(user['mobile'])
        : 'N/A';

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    AppConstants.companyName ?? 'Unknown Company',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      font: ttf,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    AppConstants.companyAddress ?? 'Unknown Address',
                    style: pw.TextStyle(fontSize: 12, font: ttf),
                  ),
                  if (isGstApplied)
                    pw.Text(
                      'GSTIN: ${AppConstants.merchantGstNumber ?? 'N/A'}',
                      style: pw.TextStyle(fontSize: 12, font: ttf),
                    ),
                  pw.Text(
                    'Merchant: $userName',
                    style: pw.TextStyle(fontSize: 12, font: ttf),
                  ),
                  pw.Text(
                    'Mobile: $userMobile',
                    style: pw.TextStyle(fontSize: 12, font: ttf),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Payment Receipt',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      font: ttf,
                    ),
                  ),
                  pw.Text(
                    'Date: $date',
                    style: pw.TextStyle(fontSize: 12, font: ttf),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Customer Details',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                font: ttf,
              ),
            ),
            pw.Text(
              'Name: $userName',
              style: pw.TextStyle(font: ttf),
            ),
            pw.Text(
              'Mobile: $userMobile',
              style: pw.TextStyle(font: ttf),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Order Summary',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                font: ttf,
              ),
            ),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Item',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: ttf,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Price',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: ttf,
                        ),
                      ),
                    ),
                  ],
                ),
                ...safeOrders.expand((order) {
                  final items = order is Map && order['items'] is List
                      ? order['items'] as List
                      : [];
                  return items.map((item) {
                    final menuItem = item is Map ? item : {};
                    final String itemName = menuItem['name'] != null
                        ? _sanitizeText(menuItem['name'])
                        : 'Unknown Item';
                    final int quantity = (menuItem['quantity'] is num)
                        ? (menuItem['quantity'] as num).toInt()
                        : 1;
                    final num pricePerUnit = (menuItem['price'] is num)
                        ? menuItem['price'] as num
                        : 0;
                    final num price = pricePerUnit * quantity;
                    final String customization =
                        menuItem['customization'] != null
                            ? _sanitizeText(menuItem['customization'])
                            : '';
                    final String displayName = customization.isNotEmpty
                        ? '$itemName [$customization]'
                        : itemName;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '$displayName x$quantity',
                            style: pw.TextStyle(font: ttf),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${AppConstants.rupeeSymbol ?? '₹'}${price.toString()}',
                            style: pw.TextStyle(font: ttf),
                          ),
                        ),
                      ],
                    );
                  });
                }).toList(),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.teal100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Subtotal',
                        style: pw.TextStyle(font: ttf),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '${AppConstants.rupeeSymbol ?? '₹'}${totalPrice.toString()}',
                        style: pw.TextStyle(font: ttf),
                      ),
                    ),
                  ],
                ),
                if (isGstApplied)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'GST (${((AppConstants.gstRate ?? 0.0) * 100).toString()}%)',
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${AppConstants.rupeeSymbol ?? '₹'}${gstAmount.toString()}',
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                    ],
                  ),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Total Amount',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: ttf,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '${AppConstants.rupeeSymbol ?? '₹'}${total.toString()}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: ttf,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Payment Details',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                font: ttf,
              ),
            ),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Field',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: ttf,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Details',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: ttf,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Payment Method',
                        style: pw.TextStyle(font: ttf),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        paymentMethod,
                        style: pw.TextStyle(font: ttf),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Transaction ID',
                        style: pw.TextStyle(font: ttf),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        transactionId,
                        style: pw.TextStyle(font: ttf),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Payment Status',
                        style: pw.TextStyle(font: ttf),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        paymentStatus,
                        style: pw.TextStyle(font: ttf),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Thank you for your purchase!',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      font: ttf,
                    ),
                  ),
                  pw.Text(
                    'Come visit us again at ${AppConstants.companyName ?? 'Unknown Company'}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontStyle: pw.FontStyle.italic,
                      font: ttf,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  // ========================================================
  // 2. Generate Receipt (Web = Print, Mobile = Save + Open)
  // ========================================================
  Future<String> generateReceiptPdf(dynamic response, List<dynamic> orders,
      dynamic user, bool isGstApplied) async {
    try {
      final pdf = await _buildPdfDocument(response, orders, user, isGstApplied);

      if (kIsWeb) {
        // Web: Open Print Dialog
        await Printing.layoutPdf(
          onLayout: (_) => pdf.save(),
          name: 'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        _showSnackBar('Receipt sent to printer', Colors.green);
        return 'printed';
      } else {
        // Mobile: Save to device
        Directory? directory;
        try {
          directory = await getApplicationDocumentsDirectory();
        } catch (_) {
          directory = await getTemporaryDirectory();
        }
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final file = File(
            '${directory.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(await pdf.save());
        developer.log('PDF saved at: ${file.path}', name: 'CheckoutScreen');

        final openResult = await OpenFilex.open(file.path);
        if (openResult.type != ResultType.done) {
          _showSnackBar(
              'Saved at ${file.path} (could not open)', AppConstants.errorColor);
        } else {
          _showSnackBar('Receipt opened', Colors.green);
        }
        return file.path;
      }
    } catch (e, stackTrace) {
      developer.log('Error generating receipt: $e', stackTrace: stackTrace);
      _showSnackBar('Failed to generate receipt: $e', AppConstants.errorColor);
      final receiptContent = await _generateReceiptContent(
          response, orders, user, isGstApplied,
          showDialogOnFailure: true);
      return receiptContent;
    }
  }

  Future<String> _generateReceiptContent(
      dynamic response, List<dynamic> orders, dynamic user, bool isGstApplied,
      {bool showDialogOnFailure = false}) async {
    try {
      final safeOrders = orders.where((order) => order != null).toList();
      final double totalPrice = safeOrders.fold(
        0.0,
        (sum, order) =>
            sum +
            ((order is Map && order['total'] is num)
                ? order['total'].toDouble()
                : 0.0),
      );
      final double gstAmount =
          isGstApplied ? totalPrice * (AppConstants.gstRate ?? 0.0) : 0.0;
      final double total = totalPrice + gstAmount;

      final Map<String, String> paymentMethodMap = {
        'UPI': 'UPI',
        'DYNAMIC_QR': 'Dynamic QR',
        'CHALLAN': 'Challan',
        'ENACH': 'eNACH',
        'EFTNET': 'NEFT/RTGS',
        'PAYTM': 'Paytm',
        'PHONEPE': 'PhonePe',
        'AMAZONPAY': 'Amazon Pay',
        'FREECHARGE': 'FreeCharge',
        'JIOMONEY': 'JioMoney',
        'OLAMONEY': 'Ola Money',
        'AIRTELMONEY': 'Airtel Money',
        'PAYZAPP': 'PayZapp',
        'CC': 'Credit Card',
        'DC': 'Debit Card',
        'MASTERCARD': 'MasterCard',
        'VISA': 'Visa',
        'VISA_ELECTRON': 'Visa Electron',
        'RUPAY': 'RuPay',
        'AMEX': 'American Express',
        'DINERS': 'Diners Club',
        'MAESTRO': 'Maestro',
        'NB': 'Net Banking',
        'EMI': 'EMI',
        'EMI_DC': 'Debit Card EMI',
        'EMI_CARDLESS': 'Cardless EMI',
        'LAZYPAY': 'LazyPay',
        'OLA_POSTPAID': 'Ola Postpaid',
        'PAYPAL': 'PayPal',
        'PLUXEE': 'Pluxee (Sodexo Meal Card)',
        'WALLET': 'Wallet',
        'CASH': 'Cash',
        'Cash': 'Cash',
        'Online': 'Online'
      };

      final payuResponse =
          response is Map && response.containsKey('payuResponse')
              ? response['payuResponse']
              : null;
      String paymentMethod = 'Unknown';
      if (payuResponse != null) {
        if (payuResponse is String) {
          try {
            final decoded = jsonDecode(payuResponse) as Map;
            paymentMethod =
                paymentMethodMap[decoded['mode']?.toString()] ?? 'Unknown';
          } catch (e) {
            developer.log('Error decoding payuResponse string: $e',
                name: 'CheckoutScreen');
          }
        } else if (payuResponse is Map) {
          paymentMethod =
              paymentMethodMap[payuResponse['mode']?.toString()] ?? 'Unknown';
        }
      }

      final String transactionId =
          payuResponse is Map && payuResponse['txnid'] is String
              ? payuResponse['txnid']
              : 'TXN${Random().nextInt(1000000).toString().padLeft(6, '0')}';
      final String paymentStatus =
          payuResponse is Map && payuResponse['status'] is String
              ? payuResponse['status'].toUpperCase()
              : 'SUCCESS';
      final String date = DateTime.now().toString().split(' ').first;

      final String userName = user is Map && user['fullName'] != null
          ? _sanitizeText(user['fullName'])
          : 'Unknown User';
      final String userMobile = user is Map && user['mobile'] != null
          ? _sanitizeText(user['mobile'])
          : 'N/A';

      String receiptContent = '''
${_sanitizeText(AppConstants.companyName ?? 'Unknown Company')}
${_sanitizeText(AppConstants.companyAddress ?? 'Unknown Address')}
${isGstApplied ? 'GSTIN: ${_sanitizeText(AppConstants.merchantGstNumber ?? 'N/A')}' : ''}
Merchant: $userName
Mobile: $userMobile
Payment Receipt
Date: $date
Customer Details
Name: $userName
Mobile: $userMobile
Order Summary
${safeOrders.expand((order) {
        final items = order is Map && order['items'] is List
            ? order['items'] as List
            : [];
        return items.map((item) {
          final menuItem = item is Map ? item : {};
          final String itemName = menuItem['name'] != null
              ? _sanitizeText(menuItem['name'])
              : 'Unknown Item';
          final int quantity = (menuItem['quantity'] is num)
              ? (menuItem['quantity'] as num).toInt()
              : 1;
          final num pricePerUnit =
              (menuItem['price'] is num) ? menuItem['price'] as num : 0;
          final num price = pricePerUnit * quantity;
          final String customization = menuItem['customization'] != null
              ? _sanitizeText(menuItem['customization'])
              : '';
          final String displayName = customization.isNotEmpty
              ? '$itemName [$customization]'
              : itemName;
          return '$displayName x$quantity: ${AppConstants.rupeeSymbol ?? '₹'}${price.toString()}';
        });
      }).join('\n')}
Subtotal: ${AppConstants.rupeeSymbol ?? '₹'}${totalPrice.toString()}
${isGstApplied ? 'GST (${((AppConstants.gstRate ?? 0.0) * 100).toString()}%): ${AppConstants.rupeeSymbol ?? '₹'}${gstAmount.toString()}' : ''}
Total Amount: ${AppConstants.rupeeSymbol ?? '₹'}${total.toString()}
Payment Details
Payment Method: $paymentMethod
Transaction ID: $transactionId
Payment Status: $paymentStatus
Thank you for your purchase!
Come visit us again at ${_sanitizeText(AppConstants.companyName ?? 'Unknown Company')}
''';

      if (showDialogOnFailure && mounted) {
        _showReceiptDialog(receiptContent);
      }
      return receiptContent;
    } catch (e, stackTrace) {
      developer.log(
          'Error generating receipt content: $e, StackTrace: $stackTrace',
          name: 'CheckoutScreen');
      _showSnackBar(
          'Failed to generate receipt content: $e', AppConstants.errorColor);
      return '';
    }
  }

  bool _isValidMobile(String mobile) {
    return RegExp(r'^\d{10}$').hasMatch(mobile);
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
        margin: const EdgeInsets.all(AppConstants.paddingSmall),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showReceiptDialog(String receiptContent) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Receipt Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            receiptContent,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return BlocListener<BillBloc, BillState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          developer.log('BillBloc error: ${state.error}',
              name: 'CheckoutScreen');
        }
        setState(() {
          _isLoading = state.isLoading;
          if (!state.isLoading) {
            developer.log('Processing bills: ${state.bills}',
                name: 'CheckoutScreen');
            final pendingBills = state.bills.where((bill) {
              final status = bill['status'] ?? 'Pending';
              return status == 'Pending';
            }).toList();
            developer.log('Pending bills: $pendingBills',
                name: 'CheckoutScreen');
            _groupedBills = {};
            _tableTotals = {};
            _grandTotal = 0.0;
            for (var bill in pendingBills) {
              final table = bill['table'] as String? ?? 'Unknown';
              _groupedBills.putIfAbsent(table, () => []).add(bill);
              final billId = bill['billId'] as String? ?? '';
              _mobileControllers.putIfAbsent(
                  billId,
                  () => TextEditingController(
                      text: bill['user']?['mobile'] ?? ''));
            }
            _groupedBills.forEach((table, bills) {
              double tableTotal = bills.fold(0.0, (sum, bill) {
                final amount = (bill['totalAmount'] as num?)?.toDouble() ?? 0.0;
                developer.log('Bill ${bill['billId']} totalAmount: $amount',
                    name: 'CheckoutScreen');
                return sum + amount;
              });
              _tableTotals[table] = tableTotal;
              _grandTotal += tableTotal;
            });
            developer.log('Grouped bills: $_groupedBills',
                name: 'CheckoutScreen');
            developer.log('Table totals: $_tableTotals',
                name: 'CheckoutScreen');
            developer.log('Grand total: $_grandTotal', name: 'CheckoutScreen');
          }
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Checkout',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.indigo[700],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => context.read<BillBloc>().add(FetchBills()),
              tooltip: 'Refresh Bills',
            ),
          ],
        ),
        body: Container(
          color: Colors.grey[100],
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill Summary',
                  style: TextStyle(
                    fontSize: isTablet ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BlocBuilder<BillBloc, BillState>(
                    builder: (context, state) {
                      if (_isLoading) {
                        developer.log('Showing loading indicator',
                            name: 'CheckoutScreen');
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.indigo),
                          ),
                        );
                      }
                      if (_groupedBills.isEmpty) {
                        developer.log('No pending bills to display',
                            name: 'CheckoutScreen');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No pending bills for payment',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      developer.log('Rendering ${_groupedBills.length} tables',
                          name: 'CheckoutScreen');
                      return ListView.builder(
                        itemCount: _groupedBills.length,
                        itemBuilder: (context, index) {
                          final table = _groupedBills.keys.elementAt(index);
                          final bills = _groupedBills[table]!;
                          final tableTotal = _tableTotals[table] ?? 0.0;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ExpansionTile(
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Table: $table',
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo[900],
                                    ),
                                  ),
                                  Text(
                                    '₹${tableTotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              iconColor: Colors.indigo[700],
                              collapsedIconColor: Colors.indigo[400],
                              children: bills.map((bill) {
                                final billId = bill['billId'] as String? ?? '';
                                final isProcessing =
                                    _processingBills[billId] ?? false;
                                final totalAmount =
                                    (bill['totalAmount'] as num?)?.toDouble() ??
                                        0.0;
                                final displayTotal =
                                    (bill['isGstApplied'] == true)
                                        ? (totalAmount).toStringAsFixed(2)
                                        : totalAmount.toStringAsFixed(2);
                                developer.log('Rendering bill $billId',
                                    name: 'CheckoutScreen');
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: ExpansionTile(
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bill ID: ${billId.length > 8 ? billId.substring(0, 8) + '...' : billId}',
                                          style: TextStyle(
                                            fontSize: isTablet ? 16 : 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.indigo[900],
                                          ),
                                        ),
                                        Text(
                                          'Table: ${bill['table'] ?? 'Unknown'}',
                                          style: TextStyle(
                                            fontSize: isTablet ? 15 : 13,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          'User: ${bill['user']?['fullName'] ?? 'Unknown User'}',
                                          style: TextStyle(
                                            fontSize: isTablet ? 15 : 13,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          'Total: ₹$displayTotal',
                                          style: TextStyle(
                                            fontSize: isTablet ? 15 : 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                        Text(
                                          'Status: ${bill['status'] ?? 'Pending'}',
                                          style: TextStyle(
                                            fontSize: isTablet ? 15 : 13,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          'Payment Method: ${bill['paymentMethod'] ?? 'Not Set'}',
                                          style: TextStyle(
                                            fontSize: isTablet ? 15 : 13,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    iconColor: Colors.indigo[700],
                                    collapsedIconColor: Colors.indigo[400],
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoRow(
                                                'Bill ID', billId, isTablet),
                                            _buildInfoRow(
                                                'Table',
                                                bill['table'] ?? 'Unknown',
                                                isTablet),
                                            _buildInfoRow(
                                                'User',
                                                bill['user']?['fullName'] ??
                                                    'Unknown User',
                                                isTablet),
                                            _buildInfoRow(
                                                'Email',
                                                bill['user']?['email'] ?? 'N/A',
                                                isTablet),
                                            _buildInfoRow('Total',
                                                '₹$displayTotal', isTablet,
                                                color: Colors.green[700]),
                                            _buildInfoRow(
                                                'Status',
                                                bill['status'] ?? 'Pending',
                                                isTablet),
                                            _buildInfoRow(
                                                'Payment Method',
                                                bill['paymentMethod'] ??
                                                    'Not Set',
                                                isTablet),
                                            const Divider(height: 20),
                                            Text(
                                              'Orders:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: isTablet ? 16 : 14,
                                                color: Colors.indigo[900],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ...((bill['orders'] as List?) ?? [])
                                                .map((order) {
                                              final orderId =
                                                  order['orderId'] ?? '';
                                              final orderTotal =
                                                  order['total']?.toString() ??
                                                      '0';
                                              final orderStatus =
                                                  order['status'] ?? 'Pending';
                                              final timestamp =
                                                  order['timestamp'] ?? '';
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildInfoRow('Order ID',
                                                      orderId, isTablet),
                                                  _buildInfoRow('Total',
                                                      '₹$orderTotal', isTablet),
                                                  _buildInfoRow('Status',
                                                      orderStatus, isTablet),
                                                  _buildInfoRow('Timestamp',
                                                      timestamp, isTablet),
                                                  Text(
                                                    'Items:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          isTablet ? 15 : 13,
                                                      color: Colors.indigo[900],
                                                    ),
                                                  ),
                                                  ...((order['items']
                                                              as List?) ??
                                                          [])
                                                      .map((item) {
                                                    final name = item['name'] ??
                                                        'Unnamed';
                                                    final qty = item['quantity']
                                                            ?.toString() ??
                                                        '1';
                                                    final price = item['price']
                                                            ?.toString() ??
                                                        '0';
                                                    final customization =
                                                        item['customization'] ??
                                                            '';
                                                    return Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 4.0),
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.fastfood,
                                                              size: 16,
                                                              color: Colors
                                                                  .indigo[400]),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              '$name (x$qty) ₹$price ${customization.isNotEmpty ? '[$customization]' : ''}',
                                                              style: TextStyle(
                                                                fontSize:
                                                                    isTablet
                                                                        ? 14
                                                                        : 12,
                                                                color: Colors
                                                                    .grey[800],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }),
                                                  const SizedBox(height: 8),
                                                ],
                                              );
                                            }),
                                            const Divider(height: 20),
                                            TextField(
                                              controller:
                                                  _mobileControllers[billId],
                                              decoration: InputDecoration(
                                                labelText: 'Mobile Number',
                                                labelStyle: TextStyle(
                                                    color: Colors.indigo[700]),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.indigo[200]!),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.indigo[200]!),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.indigo[700]!,
                                                      width: 2),
                                                ),
                                                prefixIcon: Icon(Icons.phone,
                                                    color: Colors.indigo[400]),
                                              ),
                                              keyboardType: TextInputType.phone,
                                              enabled: !isProcessing,
                                              style: TextStyle(
                                                  fontSize: isTablet ? 16 : 14),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: isProcessing
                                                        ? null
                                                        : () => _handlePayment(
                                                            billId, 'Cash'),
                                                    icon: const Icon(
                                                        Icons.money,
                                                        color: Colors.white),
                                                    label: Text(
                                                      isProcessing
                                                          ? 'Processing...'
                                                          : 'Pay by Cash',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.blue[600],
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 16),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      elevation: 2,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: isProcessing
                                                        ? null
                                                        : () => _handlePayment(
                                                            billId, 'Online'),
                                                    icon: const Icon(
                                                        Icons.credit_card,
                                                        color: Colors.white),
                                                    label: Text(
                                                      isProcessing
                                                          ? 'Processing...'
                                                          : 'Pay by Online',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.green[600],
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 16),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      elevation: 2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(
                  color: Colors.grey,
                  height: 32,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: isTablet ? 22 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
                      ),
                    ),
                    Text(
                      '₹${_grandTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: isTablet ? 22 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                if (_isGstApplied)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '(Including GST where applicable)',
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isTablet,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: isTablet ? 15 : 13,
              fontWeight: FontWeight.w600,
              color: Colors.indigo[900],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 15 : 13,
                color: color ?? Colors.grey[800],
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}