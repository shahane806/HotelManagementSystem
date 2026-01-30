import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import '../app/constants.dart';
import '../bloc/BillBloc/bloc.dart';
import '../bloc/BillBloc/event.dart';
import '../bloc/BillBloc/state.dart';
import '../repositories/bill_pdf.dart';
import '../services/apiServicesCheckout.dart';
import '../services/socketService.dart';

import './checkout_analytics_screen.dart';
// ───────────────────────────────────────────────
// Main Checkout Screen (AppBar already updated)
// ───────────────────────────────────────────────
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
      if (context.mounted)
        showSnackBar('Please enter mobile number', Colors.red, context);
      return;
    }

    final mobile = controller.text.trim();
    print("Hello : ${mobile}");
    if (!_isValidMobile(mobile)) {
      if (context.mounted)
        showSnackBar(
            'Enter a valid 10-digit mobile number', Colors.red, context);
      return;
    }

    setState(() {
      _processingBills[billId] = true;
      _selectedPaymentMethods[billId] = method;
    });

    final bill = _findBillById(billId);
    print("OM Shahane : ${bill}");
    if (bill == null) {
      if (context.mounted) showSnackBar('Bill not found', Colors.red, context);
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
      final fakeResponse = {
        'payuResponse': {
          'mode': method,
          'txnid': billId,
          'status': 'success',
        }
      };

      await Apiservicescheckout.updateBillStatus(
          billId, 'Paid', method, mobile, fakeResponse);
      socketService.payBill(billData);
      if (context.mounted)
        showSnackBar('Payment processed via $method', Colors.green, context);

      // Generate receipt

      await generateReceiptPdf(
          fakeResponse,
          bill['orders'] as List<dynamic>? ?? [],
          bill['user'],
          mobile,
          bill['isGstApplied'] as bool? ?? false,
          context);

      context.read<BillBloc>().add(
            UpdateBill(
              billId,
              'Paid',
              paymentMethod: method,
              transaction: fakeResponse, // send the transaction info
            ),
          );

      context.read<BillBloc>().add(FetchBills());
    } catch (e) {
      developer.log('Payment failed: $e', name: 'Checkout');
      if (context.mounted)
        showSnackBar('Payment failed. Please try again.', Colors.red, context);
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

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 700;

    return BlocListener<BillBloc, BillState>(
      listener: (context, state) {
        if (state.error != null) {
          if (context.mounted) showSnackBar(state.error!, Colors.red, context);
        }

        if (!state.isLoading && state.bills.isNotEmpty) {
          setState(() {
            _isLoading = false;

            final pending = state.bills
                .where((b) =>
                    (b['status']?.toString() ?? '').toLowerCase() == 'pending')
                .toList();

            _groupedBills.clear();
            _tableTotals.clear();
            _grandTotal = 0;

            for (final bill in pending) {
              final table = bill['table']?.toString() ?? 'Other';
              _groupedBills
                  .putIfAbsent(table, () => [])
                  .add(bill.cast<String, dynamic>());

              final billId = bill['billId']?.toString() ?? '';
              _mobileControllers.putIfAbsent(
                billId,
                () => TextEditingController(
                    text: bill['user']?['mobile']?.toString() ?? ''),
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
          elevation: 2,
          actions: [
            SizedBox(
              width: 48,
              child: IconButton(
                icon: const Icon(Icons.analytics_rounded),
                // tooltip: 'View Sales & Collection Analytics',
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const AnalyticsScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        // Use a simple fade or no animation to avoid FractionalTranslation issues
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: 48,
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded),
                // tooltip: 'Refresh Bills List',
                onPressed: () => context.read<BillBloc>().add(FetchBills()),
              ),
            ),
            const SizedBox(width: 8),
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
            style:
                GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade600),
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

  Widget _buildTableGroup(String table, List<Map<String, dynamic>> bills,
      double total, bool isTablet) {
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

    final gstAmount =
        bill['isGstApplied'] == true ? subTotal * (AppConstants.gstRate) : 0.0;
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
                Text(
                  '₹${subTotal.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            if (gstAmount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GST (${(AppConstants.gstRate * 100).toStringAsFixed(1)}%)',
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
              style: GoogleFonts.poppins(
                  fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _mobileControllers[billId],
              decoration: InputDecoration(
                hintText: '10-digit mobile number',
                prefixIcon: const Icon(Icons.phone, size: 20),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
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
                    onPressed: isProcessing
                        ? null
                        : () => _handlePayment(billId, 'Cash'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentButton(
                    label: 'Online / UPI',
                    icon: Icons.qr_code_scanner,
                    color: Colors.green.shade700,
                    isLoading: isProcessing,
                    onPressed: isProcessing
                        ? null
                        : () => _handlePayment(billId, 'Online'),
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
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
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
