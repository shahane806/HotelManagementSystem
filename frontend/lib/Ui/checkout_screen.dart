import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../services/socketService.dart';

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
  final Map<String, String> _selectedPaymentMethods = {};

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
    developer.log('CheckoutScreen initialized', name: 'Checkout');
  }

  @override
  void dispose() {
    socketService.socket.off('newBill', _onNewBill);
    socketService.socket.off('billPaid', _onBillPaid);
    socketService.socket.off('orderUpdated', _onOrderUpdated);
    socketService.socket.off('error', _onError);
    socketService.disconnect();

    for (var controller in _mobileControllers.values) {
      controller.dispose();
    }

    developer.log('CheckoutScreen disposed', name: 'Checkout');
    super.dispose();
  }

  // ───────────────────────────────────────────────
  // Socket Listeners
  // ───────────────────────────────────────────────
  void _onNewBill(dynamic data) {
    developer.log('New bill: $data', name: 'Checkout');
    context.read<BillBloc>().add(AddBill(Map<String, dynamic>.from(data)));
    context.read<BillBloc>().add(FetchBills());
  }

  void _onBillPaid(dynamic data) {
    final billId = data['billId'] as String?;
    developer.log('Bill paid: $billId', name: 'Checkout');

    if (billId != null && mounted) {
      context.read<BillBloc>().add(UpdateBill(
        billId,
        data['status'] ?? 'Paid',
        paymentMethod: data['paymentMethod'],
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful for bill $billId'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() => _processingBills[billId] = false);
      context.read<BillBloc>().add(FetchBills());
    }
  }

  void _onOrderUpdated(dynamic data) {
    developer.log('Order updated', name: 'Checkout');
    context.read<BillBloc>().add(FetchBills());
  }

  void _onError(dynamic data) {
    final message = data['message']?.toString() ?? 'Unknown error';
    final billId = data['billId'] as String?;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (billId != null) {
        setState(() => _processingBills[billId] = false);
      }
    }
  }

  // ───────────────────────────────────────────────
  // Payment Handler
  // ───────────────────────────────────────────────
  Future<void> _handlePayment(String billId, String method) async {
    final controller = _mobileControllers[billId];
    if (controller == null || controller.text.trim().isEmpty) {
      _showSnackBar('Please enter mobile number', Colors.red);
      return;
    }

    final mobile = controller.text.trim();
    if (!_isValidMobile(mobile)) {
      _showSnackBar('Enter a valid 10-digit mobile number', Colors.red);
      return;
    }

    setState(() {
      _processingBills[billId] = true;
      _selectedPaymentMethods[billId] = method;
    });

    final bill = _findBillById(billId);
    if (bill == null) {
      _showSnackBar('Bill not found', Colors.red);
      setState(() => _processingBills[billId] = false);
      return;
    }

    final billData = {
      'billId': billId,
      'table': bill['table'] ?? 'Unknown',
      'totalAmount': (bill['totalAmount'] as num?)?.toDouble() ?? 0.0,
      'orders': bill['orders'] ?? [],
      'paymentMethod': method,
      'mobile': mobile,
      'user': bill['user'] ?? {},
      'isGstApplied': bill['isGstApplied'] ?? false,
      'status': 'Paid',
    };

    try {
      await Apiservicescheckout.updateBillStatus(billId, 'Paid', method);
      socketService.payBill(billData);

      _showSnackBar('Payment processed via $method', Colors.green);

      // Generate receipt
      final fakeResponse = {
        'payuResponse': {
          'mode': method,
          'txnid': billId,
          'status': 'success',
        }
      };

      await generateReceiptPdf(
        fakeResponse,
        bill['orders'] as List<dynamic>? ?? [],
        bill['user'],
        bill['isGstApplied'] as bool? ?? false,
      );

      context.read<BillBloc>().add(UpdateBill(billId, 'Paid', paymentMethod: method));
      context.read<BillBloc>().add(FetchBills());
    } catch (e) {
      developer.log('Payment failed: $e', name: 'Checkout');
      _showSnackBar('Payment failed. Please try again.', Colors.red);
      setState(() => _processingBills[billId] = false);
    }
  }

  Map<String, dynamic>? _findBillById(String billId) {
    for (var bills in _groupedBills.values) {
      for (var bill in bills) {
        if (bill['billId'] == billId) return bill;
      }
    }
    return null;
  }

  bool _isValidMobile(String mobile) => RegExp(r'^\d{10}$').hasMatch(mobile);

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // PDF Generation (kept mostly same, minor cleanups)
  // ───────────────────────────────────────────────

  Future<pw.Document> _buildPdfDocument(
    dynamic response,
    List<dynamic> orders,
    dynamic user,
    bool isGstApplied,
  ) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    final safeOrders = orders.whereType<Map>().toList();

    final double subTotal = safeOrders.fold(
      0.0,
      (sum, order) => sum + (order['total'] as num? ?? 0).toDouble(),
    );

    final double gstAmount = isGstApplied ? subTotal * (AppConstants.gstRate ?? 0) : 0;
    final double grandTotal = subTotal + gstAmount;

    final paymentInfo = _extractPaymentInfo(response);

    final String date = DateTime.now().toString().split(' ').first;
    final String userName = _sanitize(user['fullName']) ?? 'Guest';
    final String userMobile = _sanitize(user['mobile']) ?? 'N/A';

    pdf.addPage(
      pw.Page(
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Center(
              child: pw.Column(children: [
                pw.Text(
                  AppConstants.companyName ?? 'Restaurant',
                  style: pw.TextStyle(font: ttf, fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  AppConstants.companyAddress ?? '',
                  style: pw.TextStyle(font: ttf, fontSize: 11),
                  textAlign: pw.TextAlign.center,
                ),
                if (isGstApplied)
                  pw.Text(
                    'GSTIN: ${AppConstants.merchantGstNumber ?? 'N/A'}',
                    style: pw.TextStyle(font: ttf, fontSize: 11),
                  ),
                pw.SizedBox(height: 12),
                pw.Text('Payment Receipt', style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: $date', style: pw.TextStyle(font: ttf, fontSize: 11)),
              ]),
            ),

            pw.SizedBox(height: 24),

            // Customer
            _pdfSectionTitle('Customer', ttf),
            pw.Text('Name: $userName', style: pw.TextStyle(font: ttf, fontSize: 12)),
            pw.Text('Mobile: $userMobile', style: pw.TextStyle(font: ttf, fontSize: 12)),

            pw.SizedBox(height: 20),

            // Items
            _pdfSectionTitle('Items', ttf),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue50),
                  children: [
                    _pdfCell('Item', ttf, bold: true),
                    _pdfCell('Qty', ttf, bold: true, align: pw.TextAlign.center),
                    _pdfCell('Price', ttf, bold: true, align: pw.TextAlign.right),
                  ],
                ),
                ..._buildItemRows(safeOrders, ttf),
                pw.TableRow(children: [
                  _pdfCell('Subtotal', ttf, bold: true),
                  pw.SizedBox(),
                  _pdfCell('${AppConstants.rupeeSymbol}$subTotal', ttf, align: pw.TextAlign.right),
                ]),
                if (isGstApplied)
                  pw.TableRow(children: [
                    _pdfCell('GST (${(AppConstants.gstRate! * 100).toStringAsFixed(1)}%)', ttf),
                    pw.SizedBox(),
                    _pdfCell('${AppConstants.rupeeSymbol}${gstAmount.toStringAsFixed(2)}', ttf, align: pw.TextAlign.right),
                  ]),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.teal50),
                  children: [
                    _pdfCell('Grand Total', ttf, bold: true),
                    pw.SizedBox(),
                    _pdfCell('${AppConstants.rupeeSymbol}${grandTotal.toStringAsFixed(2)}', ttf, bold: true, align: pw.TextAlign.right),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            // Payment
            _pdfSectionTitle('Payment', ttf),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(children: [_pdfCell('Method', ttf, bold: true), _pdfCell(paymentInfo.method, ttf)]),
                pw.TableRow(children: [_pdfCell('Transaction ID', ttf, bold: true), _pdfCell(paymentInfo.txnId, ttf)]),
                pw.TableRow(children: [_pdfCell('Status', ttf, bold: true), _pdfCell(paymentInfo.status, ttf)]),
              ],
            ),

            pw.Spacer(),
            pw.Center(
              child: pw.Text(
                'Thank You! Visit Again',
                style: pw.TextStyle(font: ttf, fontSize: 14, fontStyle: pw.FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  pw.Widget _pdfSectionTitle(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(title, style: pw.TextStyle(font: font, fontSize: 15, fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _pdfCell(String text, pw.Font font, {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontWeight: bold ? pw.FontWeight.bold : null),
        textAlign: align,
      ),
    );
  }

  List<pw.TableRow> _buildItemRows(List<Map> orders, pw.Font font) {
    final rows = <pw.TableRow>[];

    for (final order in orders) {
      final items = (order['items'] as List?)?.whereType<Map>() ?? [];
      for (final item in items) {
        final name = _sanitize(item['name']) ?? 'Item';
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final custom = _sanitize(item['customization']) ?? '';

        final displayName = custom.isEmpty ? name : '$name ($custom)';

        rows.add(pw.TableRow(children: [
          _pdfCell('$displayName', font),
          _pdfCell('$qty', font, align: pw.TextAlign.center),
          _pdfCell('${AppConstants.rupeeSymbol}${(price * qty).toStringAsFixed(0)}', font, align: pw.TextAlign.right),
        ]));
      }
    }
    return rows;
  }

  ({String method, String txnId, String status}) _extractPaymentInfo(dynamic response) {
    String method = 'Unknown';
    String txnId = '—';
    String status = 'SUCCESS';

    final payu = response is Map ? response['payuResponse'] : null;

    if (payu is Map) {
      method = payu['mode']?.toString() ?? 'Unknown';
      txnId = payu['txnid']?.toString() ?? '—';
      status = (payu['status']?.toString() ?? 'success').toUpperCase();
    }

    return (method: method, txnId: txnId, status: status);
  }

  String _sanitize(dynamic val) {
    final str = val?.toString() ?? '';
    return str
        .replaceAll('&', 'and')
        .replaceAll('%', 'percent')
        .replaceAll('\$', 'Rs')
        .replaceAll('#', 'No.')
        .replaceAll(RegExp(r'[\{\}\~\^\`]'), '');
  }

  // ───────────────────────────────────────────────
  // PDF Generation & Save / Print
  // ───────────────────────────────────────────────
  Future<String> generateReceiptPdf(
    dynamic response,
    List<dynamic> orders,
    dynamic user,
    bool isGstApplied,
  ) async {
    try {
      final pdf = await _buildPdfDocument(response, orders, user, isGstApplied);
      final bytes = await pdf.save();

      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (_) => bytes,
          name: 'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        _showSnackBar('Receipt ready to print', Colors.green);
        return 'printed';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File(path);
        await file.writeAsBytes(bytes);

        final result = await OpenFilex.open(path);
        if (result.type == ResultType.done) {
          _showSnackBar('Receipt opened', Colors.green);
        } else {
          _showSnackBar('Receipt saved at $path', Colors.blueGrey);
        }
        return path;
      }
    } catch (e, st) {
      developer.log('PDF generation failed: $e', stackTrace: st, name: 'Checkout');
      _showSnackBar('Could not generate PDF receipt', Colors.orange);
      return '';
    }
  }

  // ───────────────────────────────────────────────
  // UI BUILD
  // ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 700;

    return BlocListener<BillBloc, BillState>(
      listener: (context, state) {
        if (state.error != null) {
          _showSnackBar(state.error!, Colors.red);
        }

        if (!state.isLoading && state.bills.isNotEmpty) {
          setState(() {
            _isLoading = false;

            final pending = state.bills
                .where((b) => (b['status']?.toString() ?? '').toLowerCase() == 'pending')
                .toList();

            _groupedBills.clear();
            _tableTotals.clear();
            _grandTotal = 0;

            for (final bill in pending) {
              final table = bill['table']?.toString() ?? 'Other';
              _groupedBills.putIfAbsent(table, () => []).add(bill.cast<String, dynamic>());

              final billId = bill['billId']?.toString() ?? '';
              _mobileControllers.putIfAbsent(
                billId,
                () => TextEditingController(text: bill['user']?['mobile']?.toString() ?? ''),
              );
            }

            for (final entry in _groupedBills.entries) {
              final total = entry.value.fold<double>(
                0.0,
                (sum, b) => sum + (b['totalAmount'] as num? ?? 0).toDouble(),
              );
              _tableTotals[entry.key] = total;
              _grandTotal += total;
            }
          });
        } else if (state.isLoading) {
          setState(() => _isLoading = true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Checkout & Payments'),
          backgroundColor: Colors.indigo.shade700,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<BillBloc>().add(FetchBills()),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _groupedBills.isEmpty
                ? _buildEmptyState()
                : _buildContent(isTablet),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_outlined, size: 90, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(
            'No pending bills to settle',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New orders will appear here automatically',
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Bills',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.w700,
              color: Colors.indigo.shade900,
            ),
          ),
          const SizedBox(height: 20),

          ..._groupedBills.entries.map((entry) {
            final table = entry.key;
            final bills = entry.value;
            final tableTotal = _tableTotals[table] ?? 0.0;

            return _buildTableGroup(table, bills, tableTotal, isTablet);
          }),

          const Divider(height: 48, thickness: 1.5),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo.shade900,
                ),
              ),
              Text(
                '₹${_grandTotal.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 26 : 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          if (_isGstApplied)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '(Inclusive of GST where applicable)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTableGroup(String table, List<Map<String, dynamic>> bills, double total, bool isTablet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Table $table',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 22 : 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo.shade800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...bills.map((bill) => _buildBillCard(bill, isTablet)),
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill, bool isTablet) {
    final billId = bill['billId']?.toString() ?? '—';
    final table = bill['table']?.toString() ?? '?';
    final userName = bill['user']?['fullName']?.toString() ?? 'Walk-in';
    final mobile = bill['user']?['mobile']?.toString() ?? '—';
    final isProcessing = _processingBills[billId] ?? false;

    // Extract and calculate all items
    final orders = bill['orders'] as List<dynamic>? ?? [];
    double subTotal = 0.0;
    final List<Map<String, dynamic>> allItems = [];

    for (final order in orders) {
      final items = (order['items'] as List<dynamic>?) ?? [];
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;

        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final itemTotal = qty * price;
        subTotal += itemTotal;

        allItems.add({
          'name': item['name']?.toString() ?? 'Unknown item',
          'customization': item['customization']?.toString() ?? '',
          'qty': qty,
          'pricePerUnit': price,
          'total': itemTotal,
        });
      }
    }

    final gstAmount = bill['isGstApplied'] == true ? subTotal * (AppConstants.gstRate ?? 0.18) : 0.0;
    final grandTotal = subTotal + gstAmount;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header – very visible
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'TABLE $table',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill #$billId',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (mobile != '—')
                        Text(
                          '• $mobile',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24, thickness: 1.2),

            // Items list – clearest part
            Text(
              'Order Items',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade800,
              ),
            ),
            const SizedBox(height: 8),

            if (allItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No items found in this bill',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              )
            else ...[
              ...allItems.map((item) {
                final displayName = item['customization'].toString().isNotEmpty
                    ? '${item['name']} (${item['customization']})'
                    : item['name'].toString();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${item['qty']}×',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo.shade600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          displayName,
                          style: GoogleFonts.poppins(fontSize: 14.5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹${(item['total'] as double).toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const Divider(height: 20),

            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                Text(
                  '₹${subTotal.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            if (gstAmount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GST (${(AppConstants.gstRate! * 100).toStringAsFixed(1)}%)',
                    style: GoogleFonts.poppins(fontSize: 14.5),
                  ),
                  Text(
                    '₹${gstAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontSize: 14.5),
                  ),
                ],
              ),
            ],

            const Divider(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'To Pay',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  '₹${grandTotal.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Mobile + Payment buttons
            Text(
              'Customer Mobile (for receipt / SMS)',
              style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _mobileControllers[billId],
              decoration: InputDecoration(
                hintText: '10-digit mobile number',
                prefixIcon: const Icon(Icons.phone, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              ),
              keyboardType: TextInputType.phone,
              enabled: !isProcessing,
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _PaymentButton(
                    label: 'Cash',
                    icon: Icons.money,
                    color: Colors.blue.shade700,
                    isLoading: isProcessing,
                    onPressed: isProcessing ? null : () => _handlePayment(billId, 'Cash'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentButton(
                    label: 'Online / UPI',
                    icon: Icons.qr_code_scanner,
                    color: Colors.green.shade700,
                    isLoading: isProcessing,
                    onPressed: isProcessing ? null : () => _handlePayment(billId, 'Online'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PaymentButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Icon(icon, size: 20),
      label: Text(
        isLoading ? 'Processing...' : label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1.5,
      ),
    );
  }
}