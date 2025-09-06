import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
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
  bool _isGstApplied = true;
  Map<String, bool> _processingBills = {};
  Map<String, TextEditingController> _mobileControllers = {};
  Map<String, String?> _selectedPaymentMethods = {};

  @override
  void initState() {
    super.initState();
    context.read<BillBloc>().add(FetchBills());
    developer.log('CheckoutScreen initialized, fetching bills', name: 'CheckoutScreen');
  }

  @override
  void dispose() {
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
      context.read<BillBloc>().add(FetchBills());
    }
  }

  void _onOrderUpdated(dynamic data) {
    developer.log('Order updated: $data', name: 'CheckoutScreen');
    context.read<BillBloc>().add(FetchBills());
  }

  void _handlePayment(String billId, String paymentMethod) async {
    if (_mobileControllers[billId] == null || _mobileControllers[billId]!.text.isEmpty) {
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
      'billId': billId,
      'table': table,
      'totalAmount': totalAmount,
      'orders': bill['orders'] as List,
      'paymentMethod': paymentMethod,
      'mobile': mobile,
      'user': bill['user'],
      'isGstApplied': bill['isGstApplied'],
    };

    try {
      developer.log('Payment initiated for bill $billId, method $paymentMethod', name: 'CheckoutScreen');
    } catch (e) {
      developer.log('Error during payment for bill $billId: $e', name: 'CheckoutScreen');
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

  void _verifyPayment(String billId) async {
    final mobile = _mobileControllers[billId]?.text;
    final paymentMethod = _selectedPaymentMethods[billId];

    if (mobile == null || mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a mobile number for bill $billId'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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

    if (paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a payment method for bill $billId'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _processingBills[billId] = false;
    });

    try {
      await Apiservicescheckout.updateBillStatus(billId, 'Paid', paymentMethod);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment verified for bill $billId via $paymentMethod'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.read<BillBloc>().add(UpdateBill(billId, 'Paid', paymentMethod: paymentMethod));
      context.read<BillBloc>().add(FetchBills());
      developer.log('Payment verified for bill $billId, method $paymentMethod', name: 'CheckoutScreen');
    } catch (e) {
      developer.log('Error verifying payment for bill $billId: $e', name: 'CheckoutScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to verify payment for bill $billId. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isValidMobile(String mobile) {
    return RegExp(r'^\d{10}$').hasMatch(mobile);
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
          developer.log('BillBloc error: ${state.error}', name: 'CheckoutScreen');
        }
        setState(() {
          _isLoading = state.isLoading;
          if (!state.isLoading) {
            developer.log('Processing bills: ${state.bills}', name: 'CheckoutScreen');
            final pendingBills = state.bills.where((bill) {
              final status = bill['status'] ?? 'Pending';
              return status == 'Pending';
            }).toList();
            developer.log('Pending bills: $pendingBills', name: 'CheckoutScreen');
            _groupedBills = {};
            _tableTotals = {};
            _grandTotal = 0.0;
            for (var bill in pendingBills) {
              final table = bill['table'] as String;
              _groupedBills.putIfAbsent(table, () => []).add(bill);
              final billId = bill['billId'] as String;
              _mobileControllers.putIfAbsent(billId, () => TextEditingController(text: bill['user']['mobile'] ?? ''));
            }
            _groupedBills.forEach((table, bills) {
              double tableTotal = bills.fold(0.0, (sum, bill) {
                final amount = (bill['totalAmount'] as num?)?.toDouble() ?? 0.0;
                developer.log('Bill ${bill['billId']} totalAmount: $amount', name: 'CheckoutScreen');
                return sum + (bill['isGstApplied'] == true ? amount * 1.05 : amount);
              });
              _tableTotals[table] = tableTotal;
              _grandTotal += tableTotal;
            });
            developer.log('Grouped bills: $_groupedBills', name: 'CheckoutScreen');
            developer.log('Table totals: $_tableTotals', name: 'CheckoutScreen');
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
                        developer.log('Showing loading indicator', name: 'CheckoutScreen');
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                          ),
                        );
                      }
                      if (_groupedBills.isEmpty) {
                        developer.log('No pending bills to display', name: 'CheckoutScreen');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
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
                      developer.log('Rendering ${_groupedBills.length} tables', name: 'CheckoutScreen');
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                final billId = bill['billId'] as String;
                                final isProcessing = _processingBills[billId] ?? false;
                                final totalAmount = (bill['totalAmount'] as num).toDouble();
                                final displayTotal = (bill['isGstApplied'] == true)
                                    ? (totalAmount * 1.05).toStringAsFixed(2)
                                    : totalAmount.toStringAsFixed(2);
                                developer.log('Rendering bill $billId', name: 'CheckoutScreen');
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: ExpansionTile(
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bill ID: ${billId.substring(0, 8)}...',
                                          style: TextStyle(
                                            fontSize: isTablet ? 16 : 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.indigo[900],
                                          ),
                                        ),
                                        Text(
                                          'Table: ${bill['table']}',
                                          style: TextStyle(
                                            fontSize: isTablet ? 15 : 13,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          'User: ${bill['user']['fullName']}',
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
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoRow('Bill ID', billId, isTablet),
                                            _buildInfoRow('Table', bill['table'], isTablet),
                                            _buildInfoRow('User', bill['user']['fullName'], isTablet),
                                            _buildInfoRow('Email', bill['user']['email'], isTablet),
                                            _buildInfoRow('Total', '₹$displayTotal', isTablet, color: Colors.green[700]),
                                            _buildInfoRow('Status', bill['status'] ?? 'Pending', isTablet),
                                            _buildInfoRow('Payment Method', bill['paymentMethod'] ?? 'Not Set', isTablet),
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
                                            ...((bill['orders'] as List?) ?? []).map((order) {
                                              final orderId = order['orderId'] ?? '';
                                              final orderTotal = order['total'] ?? 0;
                                              final orderStatus = order['status'] ?? 'Pending';
                                              final timestamp = order['timestamp'] ?? '';
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildInfoRow('Order ID', orderId.substring(0, 8) + '...', isTablet),
                                                  _buildInfoRow('Total', '₹$orderTotal', isTablet),
                                                  _buildInfoRow('Status', orderStatus, isTablet),
                                                  _buildInfoRow('Timestamp', timestamp, isTablet),
                                                  Text(
                                                    'Items:',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: isTablet ? 15 : 13,
                                                      color: Colors.indigo[900],
                                                    ),
                                                  ),
                                                  ...((order['items'] as List?) ?? []).map((item) {
                                                    final name = item['name'] ?? 'Unnamed';
                                                    final qty = item['quantity'] ?? 1;
                                                    final price = item['price'] ?? 0;
                                                    final customization = item['customization'] ?? '';
                                                    return Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.fastfood, size: 16, color: Colors.indigo[400]),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              '$name (x$qty) ₹$price ${customization.isNotEmpty ? '[$customization]' : ''}',
                                                              style: TextStyle(
                                                                fontSize: isTablet ? 14 : 12,
                                                                color: Colors.grey[800],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                  const SizedBox(height: 8),
                                                ],
                                              );
                                            }).toList(),
                                            const Divider(height: 20),
                                            TextField(
                                              controller: _mobileControllers[billId],
                                              decoration: InputDecoration(
                                                labelText: 'Mobile Number',
                                                labelStyle: TextStyle(color: Colors.indigo[700]),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: Colors.indigo[200]!),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: Colors.indigo[200]!),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: Colors.indigo[700]!, width: 2),
                                                ),
                                                prefixIcon: Icon(Icons.phone, color: Colors.indigo[400]),
                                              ),
                                              keyboardType: TextInputType.phone,
                                              enabled: !isProcessing,
                                              style: TextStyle(fontSize: isTablet ? 16 : 14),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: isProcessing
                                                        ? null
                                                        : () => _handlePayment(billId, 'Cash'),
                                                    icon: const Icon(Icons.money, color: Colors.white),
                                                    label: Text(
                                                      isProcessing ? 'Processing...' : 'Pay by Cash',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.blue[600],
                                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
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
                                                        : () => _handlePayment(billId, 'Online'),
                                                    icon: const Icon(Icons.credit_card, color: Colors.white),
                                                    label: Text(
                                                      isProcessing ? 'Processing...' : 'Pay by Online',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.green[600],
                                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      elevation: 2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed: isProcessing ? null : () => _verifyPayment(billId),
                                              child: const Text(
                                                'Submit Payment',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.indigo[700],
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                elevation: 2,
                                                minimumSize: const Size(double.infinity, 50),
                                              ),
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

  Widget _buildInfoRow(String label, String value, bool isTablet, {Color? color}) {
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