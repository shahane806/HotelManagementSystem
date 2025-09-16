import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logging/logging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';

import '../models/order_model.dart';
import '../models/user_model.dart';

// Constants for styling (adopted from reference code)
class AppConstants {
  static const primaryColor = Color(0xFF0D6EFD);
  static const secondaryColor = Color(0xFF14B8A6);
  static const errorColor = Colors.red;
  static const backgroundColor = Color(0xFFF5F5F5);
  static const cardColor = Color(0xFFEFF6FF);
  static const textColor = Color(0xFF333333);
  static const cardElevation = 2.0;
  static const borderRadius = 8.0;
  static const paddingSmall = 16.0;
  static const paddingLarge = 16.0;
  static const animationDuration = Duration(milliseconds: 800);
  static const inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
    borderSide: BorderSide(color: Colors.grey),
  );
  static const double gstRate = 0.18; // 18% GST rate
  static const String merchantGstNumber = '27ABCDE1234F1ZG'; // Dummy GST number
  static const String companyName = 'E-Learning Solutions Pvt. Ltd.';
  static const String companyAddress =
      '123 Tech Park, Mumbai, Maharashtra, India - 400001';
  static const String companyLogoUrl =
      'https://example.com/logo.png'; // Placeholder logo URL
  static const String rupeeSymbol = '\u20B9'; // Unicode for Rupee symbol
}

class BuyPage extends StatefulWidget {
  final List<Order> orders;
  final UserModel user;
  final bool isGstApplied;

  const BuyPage({
    super.key,
    required this.orders,
    required this.user,
    required this.isGstApplied,
  });

  @override
  State<BuyPage> createState() => _BuyPageState();
}

class _BuyPageState extends State<BuyPage>
    with TickerProviderStateMixin
    implements PayUCheckoutProProtocol {
  final TextEditingController _promoCodeController = TextEditingController();
  bool _isLoading = false;
  final Logger _logger = Logger('BuyPage');

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  late PayUCheckoutProFlutter _checkoutPro;
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkoutPro = PayUCheckoutProFlutter(this);
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
    _promoCodeController.dispose();
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

  void _showConnectionLeakDialog(String errorMessage) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Connection Issue',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'A connection issue was detected with the payment service. Error: $errorMessage\n\n'
          'Please try again or contact support. For debugging, enable OkHttp logging:\n'
          'Logger.getLogger("okhttp.OkHttpClient").setLevel(Level.FINE);',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Retry',
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

  void _showPermissionSettingsDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Storage Permission Required',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Storage permission is required to save the receipt. Please enable it in the app settings.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppConstants.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: Text(
              'Open Settings',
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
                  padding: EdgeInsets.all(isMobile
                      ? AppConstants.paddingSmall
                      : AppConstants.paddingLarge),
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
          _showSnackBar(
              'Returning to previous page', AppConstants.secondaryColor);
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
        0.0, (sum, order) => sum + order.total.toDouble());
    final double gstAmount =
        widget.isGstApplied ? totalPrice * AppConstants.gstRate : 0.0;
    final double total = totalPrice + gstAmount;

    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
      color: AppConstants.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionHeader('Order Summary', Icons.receipt_long,
                isMobile: isMobile),
            const SizedBox(height: AppConstants.paddingLarge),
            ...widget.orders
                .asMap()
                .entries
                .map((entry) => _buildOrderCard(isMobile, entry.value))
                .toList(),
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
    final imagePath = order.items.isNotEmpty &&
            order.items.keys.first.menuItem.image != null &&
            order.items.keys.first.menuItem.image!.isNotEmpty
        ? order.items.keys.first.menuItem.image!
        : 'assets/images/placeholder.png';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  height: isMobile ? 60 : 80,
                  width: isMobile ? 60 : 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: isMobile ? 60 : 80,
                    width: isMobile ? 60 : 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Table: ${order.table}',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Table Service',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.secondaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppConstants.rupeeSymbol}${order.total.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          ...order.items.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key.menuItem.name} x${entry.value}',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w500,
                              color: AppConstants.textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (entry.key.customization.isNotEmpty)
                            Text(
                              'Customization: ${entry.key.customization}',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 10 : 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${AppConstants.rupeeSymbol}${(entry.key.menuItem.price * entry.value).toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textColor,
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
          _buildSummaryRow('Subtotal',
              '${AppConstants.rupeeSymbol}${price.toStringAsFixed(0)}'),
          if (widget.isGstApplied)
            _buildSummaryRow(
                'GST (${(AppConstants.gstRate * 100).toStringAsFixed(0)}%)',
                '${AppConstants.rupeeSymbol}${gstAmount.toStringAsFixed(0)}'),
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

  Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false, Color? color}) {
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
                color: color ??
                    (isTotal ? AppConstants.textColor : Colors.grey[700]),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: color ??
                  (isTotal
                      ? AppConstants.primaryColor
                      : AppConstants.textColor),
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
          borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
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

  Widget _buildSectionHeader(String title, IconData icon,
      {required bool isMobile}) {
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
              onPressed: _isLoading
                  ? null
                  : () async {
                      await makePayment();
                    },
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
                        const Icon(Icons.payment,
                            size: 20, color: Colors.white),
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

  Future<bool> makePayment() async {
    setState(() => _isLoading = true);
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() => _isLoading = false);
        _showSnackBar("No internet connection", AppConstants.errorColor);
        return false;
      }

      final random = Random().nextInt(9000) + 1000;
      String orderId =
          "U${widget.user.userId}D${DateTime.now().millisecondsSinceEpoch}R$random";
      final double totalPrice = widget.orders.fold(
          0.0, (sum, order) => sum + order.total.toDouble());
      final double gstAmount =
          widget.isGstApplied ? totalPrice * AppConstants.gstRate : 0.0;
      final String amount = (totalPrice + gstAmount).toStringAsFixed(2);

      if (widget.user.mobile.isEmpty || widget.user.email.isEmpty) {
        setState(() => _isLoading = false);
        _showSnackBar(
            "Email and mobile number are required", AppConstants.errorColor);
        return false;
      }

      _logger.info('Initiating payment for order: $orderId, amount: $amount');
      await _checkoutPro.openCheckoutScreen(
        payUPaymentParams: PayUParams.createPayUPaymentParams(
          amount,
          widget.user.fullName,
          widget.user.email,
          widget.user.mobile,
          orderId,
        ),
        payUCheckoutProConfig: PayUParams.createPayUConfigParams(),
      );

      return true;
    } catch (e, stackTrace) {
      _logger.severe("Payment Error: $e, StackTrace: $stackTrace");
      setState(() => _isLoading = false);
      if (e.toString().contains('https://in.api.clevertap.com/') &&
          e.toString().contains('leaked')) {
        _showConnectionLeakDialog(e.toString());
      } else {
        _showSnackBar(
            "Failed to initiate payment: $e", AppConstants.errorColor);
      }
      return false;
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

  // Check if storage permission is needed based on Android version
  Future<bool> _isStoragePermissionNeeded() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    _logger.info('Android SDK: $sdkInt');
    // Storage permission is only needed for Android 9 (API 28) or lower
    return sdkInt <= 28;
  }

  Future<String> _generateReceiptPdf(dynamic response) async {
    final pdf = pw.Document();

    // Load NotoSans font
    final font = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final ttf = pw.Font.ttf(font);

    final double totalPrice = widget.orders.fold(
      0.0,
      (sum, order) => sum + order.total.toDouble(),
    );
    final double gstAmount =
        widget.isGstApplied ? totalPrice * AppConstants.gstRate : 0.0;
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
      'CASH': 'Cash'
    };
    final payuResponse = response is Map && response.containsKey('payuResponse')
        ? response['payuResponse']
        : null;
    String paymentMethod = '';
    if (payuResponse != null) {
      if (payuResponse is String) {
        final decoded = jsonDecode(payuResponse);
        print("Payment mode: ${decoded['mode']}");
        paymentMethod = paymentMethodMap[decoded['mode']] ?? 'Unknown';
      } else if (payuResponse is Map) {
        print("Payment mode: ${payuResponse['mode']}");
        paymentMethod = paymentMethodMap[payuResponse['mode']] ?? 'Unknown';
      } else {
        print("Payment mode not found");
      }
    }

    final String transactionId =
        payuResponse is Map && payuResponse['txnid'] is String
            ? payuResponse['txnid']
            : 'TXN${Random().nextInt(1000000).toString().padLeft(6, '0')}';
    final String paymentStatus =
        payuResponse is Map && payuResponse['status'] is String
            ? payuResponse['status'].toString().capitalize()
            : 'Success';
    final String date = DateTime.now().toString().split(' ').first;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(AppConstants.companyName,
                      style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          font: ttf)),
                  pw.SizedBox(height: 8),
                  pw.Text(AppConstants.companyAddress,
                      style: pw.TextStyle(fontSize: 12, font: ttf)),
                  if (widget.isGstApplied)
                    pw.Text('GSTIN: ${AppConstants.merchantGstNumber}',
                        style: pw.TextStyle(fontSize: 12, font: ttf)),
                  pw.Text('Merchant: ${_sanitizeText(widget.user.fullName)}',
                      style: pw.TextStyle(fontSize: 12, font: ttf)),
                  pw.Text('Mobile: ${widget.user.mobile}',
                      style: pw.TextStyle(fontSize: 12, font: ttf)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Payment Receipt',
                      style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          font: ttf)),
                  pw.Text('Date: $date',
                      style: pw.TextStyle(fontSize: 12, font: ttf)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Customer Details',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttf)),
            pw.Text('Name: ${_sanitizeText(widget.user.fullName)}',
                style: pw.TextStyle(font: ttf)),
            pw.Text('Mobile: ${widget.user.mobile}',
                style: pw.TextStyle(font: ttf)),
            pw.SizedBox(height: 20),
            pw.Text('Order Summary',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttf)),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Item',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, font: ttf)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Price',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, font: ttf)),
                    ),
                  ],
                ),
                ...widget.orders.expand((order) => order.items.entries.map((entry) {
                      final int price = entry.key.menuItem.price * entry.value;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                _sanitizeText('${entry.key.menuItem.name} x${entry.value}'),
                                style: pw.TextStyle(font: ttf)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                '${AppConstants.rupeeSymbol}${price.toStringAsFixed(0)}',
                                style: pw.TextStyle(font: ttf)),
                          ),
                        ],
                      );
                    })).toList(),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.teal100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child:
                          pw.Text('Subtotal', style: pw.TextStyle(font: ttf)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                          '${AppConstants.rupeeSymbol}${totalPrice.toStringAsFixed(0)}',
                          style: pw.TextStyle(font: ttf)),
                    ),
                  ],
                ),
                if (widget.isGstApplied)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                            'GST (${(AppConstants.gstRate * 100).toStringAsFixed(0)}%)',
                            style: pw.TextStyle(font: ttf)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                            '${AppConstants.rupeeSymbol}${gstAmount.toStringAsFixed(0)}',
                            style: pw.TextStyle(font: ttf)),
                      ),
                    ],
                  ),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total Amount',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, font: ttf)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                          '${AppConstants.rupeeSymbol}${total.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, font: ttf)),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Payment Details',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttf)),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Field',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, font: ttf)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Details',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, font: ttf)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Payment Method',
                          style: pw.TextStyle(font: ttf)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(paymentMethod,
                          style: pw.TextStyle(font: ttf)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Transaction ID',
                          style: pw.TextStyle(font: ttf)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(transactionId,
                          style: pw.TextStyle(font: ttf)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Payment Status',
                          style: pw.TextStyle(font: ttf)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(paymentStatus,
                          style: pw.TextStyle(font: ttf)),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Thank you for your purchase!',
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          font: ttf)),
                  pw.Text('Come visit us again at ${AppConstants.companyName}',
                      style: pw.TextStyle(
                          fontSize: 12,
                          fontStyle: pw.FontStyle.italic,
                          font: ttf)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/receipt_$transactionId.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

Future<String> generateReceiptPdf(dynamic response) async {
  try {
    _logger.info('Starting receipt generation with response: $response');
    bool permissionGranted = true;
    if (await _isStoragePermissionNeeded()) {
      final storageStatus = await Permission.storage.status;
      _logger.info('Storage permission status: $storageStatus');
      if (storageStatus.isPermanentlyDenied) {
        _logger.warning('Storage permission permanently denied');
        _showPermissionSettingsDialog();
        return await _generateReceiptContent(response, showDialogOnFailure: true);
      } else if (!storageStatus.isGranted) {
        final result = await Permission.storage.request();
        _logger.info('Storage permission request result: $result');
        if (result.isPermanentlyDenied) {
          _showPermissionSettingsDialog();
          return await _generateReceiptContent(response, showDialogOnFailure: true);
        }
        permissionGranted = result.isGranted;
      }
    } else {
      _logger.info('No storage permission needed for Android 10+');
    }

    if (!permissionGranted) {
      _logger.warning('Storage permission denied');
      _showSnackBar('Storage permission denied', AppConstants.errorColor);
      return await _generateReceiptContent(response, showDialogOnFailure: true);
    }

    final pdfPath = await _generateReceiptPdf(response);
    _logger.info('Receipt PDF generated at: $pdfPath');
    final openResult = await OpenFilex.open(pdfPath);
    _logger.info('OpenFilex result: $openResult');
    if (openResult.type != ResultType.done) {
      _showSnackBar('Receipt saved at $pdfPath but could not be opened', AppConstants.errorColor);
    }
    return pdfPath;
  } catch (e, stackTrace) {
    _logger.severe('Error generating receipt: $e, StackTrace: $stackTrace');
    _showSnackBar('Failed to generate receipt: $e', AppConstants.errorColor);
    return await _generateReceiptContent(response, showDialogOnFailure: true);
  }
}

Future<String> _generateReceiptContent(dynamic response,
    {bool showDialogOnFailure = false}) async {
  try {
    _logger.info('Generating plain text receipt content');
    _logger.info('User data: fullName=${widget.user.fullName}, mobile=${widget.user.mobile}');
    _logger.info('Orders: ${widget.orders.map((o) => jsonEncode(o)).toList()}');

    final double totalPrice = widget.orders.fold(
        0.0, (sum, order) => sum + order.total.toDouble());
    final double gstAmount =
        widget.isGstApplied ? totalPrice * AppConstants.gstRate : 0.0;
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
      'CASH': 'Cash'
    };

    final payuResponse =
        response is Map && response.containsKey('payuResponse')
            ? response['payuResponse']
            : null;
    String paymentMethod = '';

    if (payuResponse != null) {
      if (payuResponse is String) {
        final decoded = jsonDecode(payuResponse);
        _logger.info('Decoded payuResponse: $decoded');
        paymentMethod = paymentMethodMap[decoded['mode']] ?? 'Unknown';
      } else if (payuResponse is Map) {
        _logger.info('payuResponse map: ${payuResponse['mode']}');
        paymentMethod = paymentMethodMap[payuResponse['mode']] ?? 'Unknown';
      } else {
        _logger.warning('Payment mode not found');
      }
    }

    final String transactionId =
        payuResponse is Map && payuResponse['txnid'] is String
            ? payuResponse['txnid']
            : 'TXN${Random().nextInt(1000000).toString().padLeft(6, '0')}';
    final String paymentStatus =
        payuResponse is Map && payuResponse['status'] is String
            ? payuResponse['status'].toString().capitalize()
            : 'Success';
    final String date = DateTime.now().toString().split(' ').first;

    String receiptContent = '''
${_sanitizeText(AppConstants.companyName)}
${_sanitizeText(AppConstants.companyAddress)}
${widget.isGstApplied ? 'GSTIN: ${AppConstants.merchantGstNumber}' : ''}
Merchant: ${_sanitizeText(widget.user.fullName ?? 'Unknown User')}
Mobile: ${_sanitizeText(widget.user.mobile ?? 'N/A')}

Payment Receipt
Date: $date

Customer Details
Name: ${_sanitizeText(widget.user.fullName ?? 'Unknown User')}
Mobile: ${_sanitizeText(widget.user.mobile ?? 'N/A')}

Order Summary
${widget.orders.expand((order) => order.items.entries.map((entry) => "${_sanitizeText(entry.key.menuItem.name ?? 'Unknown Item')} x${entry.value}: ${AppConstants.rupeeSymbol}${(entry.key.menuItem.price * entry.value).toStringAsFixed(0)}")).join('\n')}
Subtotal: ${AppConstants.rupeeSymbol}${totalPrice.toStringAsFixed(0)}
${widget.isGstApplied ? 'GST (${(AppConstants.gstRate * 100).toStringAsFixed(0)}%): ${AppConstants.rupeeSymbol}${gstAmount.toStringAsFixed(0)}' : ''}
Total Amount: ${AppConstants.rupeeSymbol}${total.toStringAsFixed(0)}

Payment Details
Payment Method: $paymentMethod
Transaction ID: $transactionId
Payment Status: $paymentStatus

Thank you for your purchase!
Come visit us again at ${_sanitizeText(AppConstants.companyName)}
''';

    _logger.info('Receipt content generated successfully');
    if (showDialogOnFailure && mounted) {
      _showReceiptDialog(receiptContent);
    }
    return receiptContent;
  } catch (e, stackTrace) {
    _logger.severe('Error generating receipt content: $e, StackTrace: $stackTrace');
    _showSnackBar('Failed to generate receipt content: $e', AppConstants.errorColor);
    return '';
  }
}
  // Generate receipt content without saving to file

  @override
  void generateHash(Map response) {
    try {
      _logger.info('Hash generation input: $response');
      Map hashResponse = HashService.generateHash(response);
      _logger.info('Hash generation output: $hashResponse');
      _checkoutPro.hashGenerated(hash: hashResponse);
    } catch (e) {
      _logger.severe('Hash Generation Error: $e');
      _showSnackBar('Hash Generation Error: $e', AppConstants.errorColor);
    }
  }

  @override
  void onError(Map? response) {
    setState(() => _isLoading = false);
    _logger.info('onError response: $response');
    String errorMessage = response?['errorMsg']?.toString() ?? 'Unknown error';
    _showSnackBar('Error: $errorMessage', AppConstants.errorColor);
  }

  @override
  void onPaymentCancel(Map? response) {
    setState(() => _isLoading = false);
    _logger.info('onPaymentCancel response: $response');
    _showSnackBar('Payment cancelled', AppConstants.errorColor);
  }

  @override
  void onPaymentFailure(dynamic response) {
    setState(() => _isLoading = false);
    _logger.info('onPaymentFailure response: $response');
    _showSnackBar('Payment failed: ${response?.toString() ?? 'Unknown error'}',
        AppConstants.errorColor);
  }

  @override
  void onPaymentSuccess(dynamic response) async {
    setState(() => _isLoading = false);
    _logger.info('onPaymentSuccess response: $response');
    String receiptPath = await generateReceiptPdf(response); // Generate receipt
    if (receiptPath.isNotEmpty) {
      _showSnackBar('Payment successful', AppConstants.secondaryColor);
    } else {
      _showSnackBar('Payment successful, but receipt generation failed',
          AppConstants.errorColor);
    }

    // Navigate back to BuyPage
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BuyPage(
            orders: widget.orders,
            user: widget.user,
            isGstApplied: widget.isGstApplied,
          ),
        ),
      );
    }
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class PayUTestCredentials {
  static const merchantKey = "FDbfXn"; // Replace with your PayU merchant key
  static const merchantSalt =
      "BzfHFbtbaJMkYUBeVMAIJexf0Uf2mD2t"; // Replace with your PayU salt
  static const iosSurl =
      "http://hmtcampus360v2.net/API/AdminPanel/PayU_Url/payment-success.php"; // Your success URL
  static const iosFurl =
      "http://hmtcampus360v2.net/API/AdminPanel/PayU_Url/payment-failure.php"; // Your failure URL
  static const androidSurl =
      "http://hmtcampus360v2.net/API/AdminPanel/PayU_Url/payment-success.php"; // Your success URL
  static const androidFurl =
      "http://hmtcampus360v2.net/API/AdminPanel/PayU_Url/payment-failure.php"; // Your failure URL
  static const merchantAccessKey = "";
  static const sodexoSourceId = "";
}

class PayUParams {
  static Map createPayUPaymentParams(String amount, String firstname,
      String email, String mobile, String transactionId) {
    var additionalParam = {
      'udf1': "udf1",
      'udf3': "udf3",
      'udf4': "udf4",
      'udf5': "udf5",
      'merchantAccessKey': PayUTestCredentials.merchantAccessKey,
      'sourceId': PayUTestCredentials.sodexoSourceId,
    };

    var payUPaymentParams = {
      'key': PayUTestCredentials.merchantKey,
      'amount': amount,
      'productInfo': "SHOPPING PRODUCT",
      'firstName': firstname,
      'email': email,
      'phone': mobile,
      'ios_surl': PayUTestCredentials.iosSurl,
      'ios_furl': PayUTestCredentials.iosFurl,
      'android_surl': PayUTestCredentials.androidSurl,
      'android_furl': PayUTestCredentials.androidFurl,
      'environment': "1", // Test mode (use "0" for production)
      'userCredential': "${PayUTestCredentials.merchantKey}:$firstname",
      'transactionId': transactionId,
      'additionalParam': additionalParam,
      'enableNativeOTP': true,
      'userToken': "",
    };
    print("payUPaymentParams: $payUPaymentParams");
    return payUPaymentParams;
  }

  static Map createPayUConfigParams() {
    var paymentModesOrder = [
      {"Wallets": "PHONEPE"},
      {"UPI": ""},
      {"Wallets": ""},
      {"EMI": ""},
      {"NetBanking": ""},
    ];

    var payUCheckoutProConfig = {
      'primaryColor': "#0D6EFD",
      'secondaryColor': "#14B8A6",
      'merchantName': "SHAHANE OM PRASHANT",
      'merchantLogo': "logo",
      'showExitConfirmationOnCheckoutScreen': true,
      'showExitConfirmationOnPaymentScreen': true,
      'paymentModesOrder': paymentModesOrder,
      'merchantResponseTimeout': 30000,
      'autoSelectOtp': true,
      'waitingTime': 30000,
      'autoApprove': true,
      'merchantSMSPermission': true,
      'showCbToolbar': true,
    };
    return payUCheckoutProConfig;
  }
}

class HashService {
  static const merchantSalt = "BzfHFbtbaJMkYUBeVMAIJexf0Uf2mD2t";
  static const merchantSecretKey = "5fcd4c398830074cac484dce7a9f511d4417c49c4e65c81c364e8abb33793358";

  static Map generateHash(Map response) {
    var hashName = response[PayUHashConstantsKeys.hashName];
    var hashStringWithoutSalt = response[PayUHashConstantsKeys.hashString];
    var hashType = response[PayUHashConstantsKeys.hashType];
    var postSalt = response[PayUHashConstantsKeys.postSalt];

    var hash = "";

    if (hashType == PayUHashConstantsKeys.hashVersionV2) {
      hash = getHmacSHA256Hash(hashStringWithoutSalt, merchantSalt);
    } else if (hashName == PayUHashConstantsKeys.mcpLookup) {
      hash = getHmacSHA1Hash(hashStringWithoutSalt, merchantSecretKey);
    } else {
      var hashDataWithSalt = hashStringWithoutSalt + merchantSalt;
      if (postSalt != null) {
        hashDataWithSalt = hashDataWithSalt + postSalt;
      }
      hash = getSHA512Hash(hashDataWithSalt);
    }
    var finalHash = {hashName: hash};
    return finalHash;
  }

  static String getSHA512Hash(String hashData) {
    var bytes = utf8.encode(hashData); // data being hashed
    var hash = sha512.convert(bytes);
    return hash.toString();
  }

  static String getHmacSHA256Hash(String hashData, String salt) {
    var key = utf8.encode(salt);
    var bytes = utf8.encode(hashData);
    final hmacSha256 = Hmac(sha256, key).convert(bytes).bytes;
    final hmacBase64 = base64Encode(hmacSha256);
    return hmacBase64;
  }

  static String getHmacSHA1Hash(String hashData, String salt) {
    var key = utf8.encode(salt);
    var bytes = utf8.encode(hashData);
    var hmacSha1 = Hmac(sha1, key); // HMAC-SHA1
    var hash = hmacSha1.convert(bytes);
    return hash.toString();
  }
}