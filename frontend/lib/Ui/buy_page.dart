import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import '../app/constants.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../repositories/payu_service.dart';
import '../repositories/receipt_pdf_generator.dart';

class BuyPage extends StatefulWidget {
  final List<Order> orders;
  final UserModel user;
  final bool isGstApplied;

  const BuyPage({
    required this.orders,
    required this.user,
    required this.isGstApplied,
    super.key,
  });

  @override
  State<BuyPage> createState() => _BuyPageState();
}

class _BuyPageState extends State<BuyPage> with TickerProviderStateMixin implements PayUCheckoutProProtocol {
  late PayUCheckoutProFlutter _payU;
  late PayUService _payUService;
  final Logger _logger = Logger('BuyPage');
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _payU = PayUCheckoutProFlutter(this);
    _payUService = PayUService(payU: _payU);
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
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
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        margin: const EdgeInsets.all(AppConstants.paddingSmall),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _startPayment() async {
    setState(() => _isLoading = true);
    try {
      final totalPrice = widget.orders.fold(
        0.0,
        (sum, order) => sum + order.total.toDouble(),
      );
      final gstAmount = widget.isGstApplied ? totalPrice * AppConstants.gstRate : 0.0;
      final total = (totalPrice + gstAmount).toStringAsFixed(2);

      await _payUService.startPayment(
        userId: widget.user.userId,
        fullName: widget.user.fullName,
        email: widget.user.email,
        phone: widget.user.mobile,
        amount: total,
        productInfo: 'Restaurant Order',
      );
    } catch (e, stackTrace) {
      _logger.severe('Payment initiation error: $e', stackTrace);
      _showSnackBar('Failed to initiate payment: $e', AppConstants.errorColor);
      setState(() => _isLoading = false);
    }
  }

  @override
  void generateHash(Map response) {
    try {
      _payUService.handleHash(response);
    } catch (e, stackTrace) {
      _logger.severe('Hash generation error: $e', stackTrace);
      _showSnackBar('Hash Generation Error: $e', AppConstants.errorColor);
    }
  }

  @override
  void onPaymentSuccess(dynamic response) async {
    setState(() => _isLoading = false);
    _logger.info('Payment success: $response');
    try {
      final paymentMethodMap = {
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
      };
      final payuResponse = response is Map && response.containsKey('payuResponse') ? response['payuResponse'] : null;
      String paymentMethod = 'Unknown';
      if (payuResponse != null) {
        if (payuResponse is String) {
          final decoded = jsonDecode(payuResponse);
          paymentMethod = paymentMethodMap[decoded['mode']] ?? 'Unknown';
        } else if (payuResponse is Map) {
          paymentMethod = paymentMethodMap[payuResponse['mode']] ?? 'Unknown';
        }
      }
      final file = await ReceiptPdfGenerator.generateReceipt(
        orders: widget.orders,
        userName: widget.user.fullName,
        userMobile: widget.user.mobile,
        txnId: response['txnid'] ?? 'TXN${DateTime.now().millisecondsSinceEpoch}',
        amount: response['amount'] ?? '0.00',
        paymentMethod: paymentMethod,
        paymentStatus: response['status']?.toString() ?? 'Success',
        isGstApplied: widget.isGstApplied,
      );
      _showSnackBar('Payment successful. Receipt generated: ${file?.path}', AppConstants.secondaryColor);
    } catch (e, stackTrace) {
      _logger.severe('Receipt generation error: $e', stackTrace);
      _showSnackBar('Payment successful, but receipt generation failed: $e', AppConstants.errorColor);
    }
  }

  @override
  void onPaymentFailure(dynamic response) {
    setState(() => _isLoading = false);
    _logger.info('Payment failure: $response');
    _showSnackBar('Payment failed: ${response?.toString() ?? 'Unknown error'}', AppConstants.errorColor);
  }

  @override
  void onPaymentCancel(Map? response) {
    setState(() => _isLoading = false);
    _logger.info('Payment cancelled: $response');
    _showSnackBar('Payment cancelled', AppConstants.errorColor);
  }

  @override
  void onError(Map? response) {
    setState(() => _isLoading = false);
    _logger.info('Payment error: $response');
    _showSnackBar('Error: ${response?['errorMsg'] ?? 'Unknown error'}', AppConstants.errorColor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(
                    isMobile ? AppConstants.paddingSmall : AppConstants.paddingLarge,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 600,
                      ),
                      child: isMobile
                          ? _buildMobileLayout()
                          : _buildDesktopLayout(constraints),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Secure Checkout',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: AppConstants.primaryColor,
      elevation: 2,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          _showSnackBar('Returning to previous page', AppConstants.secondaryColor);
          Navigator.of(context).pop();
        },
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, color: Colors.white70, size: 18),
              const SizedBox(width: 4),
              Text(
                'SSL Secured',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOrderSummary(true),
        const SizedBox(height: AppConstants.paddingLarge),
        _buildPaymentSection(true),
      ],
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          flex: isTablet ? 1 : 2,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildPaymentSection(false),
          ),
        ),
        const SizedBox(width: AppConstants.paddingLarge),
        Flexible(
          flex: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _buildOrderSummary(false),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(bool isMobile) {
    final double totalPrice = widget.orders.fold(
      0.0,
      (sum, order) => sum + order.total.toDouble(),
    );
    final double gstAmount = widget.isGstApplied ? totalPrice * AppConstants.gstRate : 0.0;
    final double total = totalPrice + gstAmount;

    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      color: AppConstants.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionHeader('Order Summary', Icons.receipt_long, isMobile: isMobile),
            const SizedBox(height: AppConstants.paddingLarge),
            ...widget.orders.map((order) => _buildOrderCard(isMobile, order)).toList(),
            const SizedBox(height: AppConstants.paddingLarge),
            _buildPricingBreakdown(totalPrice, gstAmount, total),
            if (widget.isGstApplied) ...[
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                'Merchant GSTIN: ${AppConstants.merchantGstNumber}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(bool isMobile, Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Table: ${order.table} (${order.status})',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 8),
          ...order.items.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key.menuItem.name,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 12 : 14,
                          color: AppConstants.textColor,
                        ),
                      ),
                    ),
                    Text(
                      entry.key.customization.isNotEmpty ? '(${entry.key.customization})' : '',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'x${entry.value}',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 12 : 14,
                        color: AppConstants.textColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${AppConstants.rupeeSymbol}${entry.key.menuItem.price * entry.value}',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown(double price, double gstAmount, double total) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSummaryRow('Subtotal', '${AppConstants.rupeeSymbol}${price.toStringAsFixed(0)}'),
          if (widget.isGstApplied)
            _buildSummaryRow(
              'GST (${(AppConstants.gstRate * 100).toStringAsFixed(0)}%)',
              '${AppConstants.rupeeSymbol}${gstAmount.toStringAsFixed(0)}',
            ),
          const Divider(height: 24, thickness: 1),
          _buildSummaryRow(
            'Total Amount',
            '${AppConstants.rupeeSymbol}${total.toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                color: isTotal ? AppConstants.textColor : Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: isTotal ? AppConstants.primaryColor : AppConstants.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(bool isMobile) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      color: AppConstants.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionHeader('Payment', Icons.payment, isMobile: isMobile),
            const SizedBox(height: AppConstants.paddingLarge),
            _buildPayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {required bool isMobile}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppConstants.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (title == 'Payment')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 12, color: AppConstants.secondaryColor),
                const SizedBox(width: 4),
                Text(
                  '256-bit SSL',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPayButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => _scaleController.forward(),
          onTapUp: (_) => _scaleController.reverse(),
          onTapCancel: () => _scaleController.reverse(),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _startPayment,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: AppConstants.cardElevation,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.payment, size: 20, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          'Pay Now',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(
              color: AppConstants.primaryColor,
              backgroundColor: Colors.grey,
              minHeight: 3,
            ),
          ),
      ],
    );
  }
}