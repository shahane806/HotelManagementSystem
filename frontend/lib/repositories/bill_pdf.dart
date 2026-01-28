import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'package:whatsapp_share_plus/whatsapp_share_plus.dart';
import 'package:whatsapp_share_plus/whatsapp_share_plus_platform_interface.dart';

import '../app/constants.dart';

void showSnackBar(String message, Color color,
    BuildContext context) {
  if (!context.mounted) return;
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

Future<String> generateReceiptPdf(
  dynamic response,
  List<dynamic> orders,
  dynamic user,
  String? mobile,
  bool isGstApplied,
  BuildContext context,
) async {
  print("Generate Pdf is called : $response\n$orders\n$user\n$mobile\n$isGstApplied");
  try {
    final pdf =
        await buildPdfDocument(response, orders, user, mobile!, isGstApplied);
    final bytes = await pdf.save();

    if (kIsWeb) {
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: 'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      if(context.mounted){
        showSnackBar('Receipt ready to print', Colors.green,context);
      }
      return 'printed';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes);

      final result = await OpenFilex.open(path);
      if (result.type == ResultType.done) {
       if(context.mounted)  showSnackBar('Receipt opened', Colors.green ,context);
      } else {
        if(context.mounted) showSnackBar('Receipt saved at $path', Colors.blueGrey,context);
      }
      return path;
    }
  } catch (e, st) {
    developer.log('PDF generation failed: $e',
        stackTrace: st, name: 'Checkout');
    if(context.mounted)  showSnackBar('Could not generate PDF receipt', Colors.orange,context);
    return '';
  }
}

Future<pw.Document> buildPdfDocument(
  dynamic response,
  List<dynamic> orders,
  dynamic user,
  String? mobile,
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

  final double gstAmount =
      isGstApplied ? subTotal * (AppConstants.gstRate ?? 0) : 0;
  final double grandTotal = subTotal + gstAmount;

  final paymentInfo = _extractPaymentInfo(response);
  print("Om Shahane : ${paymentInfo}");
  final String date = DateTime.now().toString().split(' ').first;
  final String userName = _sanitize(user['fullName']) ?? 'Guest';
  final String userMobile = _sanitize(mobile) ?? 'N/A';

  // Build item rows once (same as before)
  final itemRows = _buildItemRows(safeOrders, ttf);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) => [
        // Header - appears only on first page
        pw.Center(
          child: pw.Column(children: [
            pw.Text(
              AppConstants.companyName ?? 'Restaurant',
              style: pw.TextStyle(
                  font: ttf, fontSize: 22, fontWeight: pw.FontWeight.bold),
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
            pw.Text('Payment Receipt',
                style: pw.TextStyle(
                    font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Date: $date',
                style: pw.TextStyle(font: ttf, fontSize: 11)),
          ]),
        ),
        pw.SizedBox(height: 24),

        // Customer info
        _pdfSectionTitle('Customer', ttf),
        pw.Text('Name: $userName',
            style: pw.TextStyle(font: ttf, fontSize: 12)),
        pw.Text('Mobile: $userMobile',
            style: pw.TextStyle(font: ttf, fontSize: 12)),
        pw.SizedBox(height: 20),

        // Items section title
        _pdfSectionTitle('Items', ttf),

        // Items table - will automatically split across pages if too long
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _pdfCell('Item', ttf, bold: true),
                _pdfCell('Qty', ttf, bold: true, align: pw.TextAlign.center),
                _pdfCell('Price', ttf, bold: true, align: pw.TextAlign.right),
              ],
            ),
            // All item rows
            ...itemRows,
            // Subtotal
            pw.TableRow(children: [
              _pdfCell('Subtotal', ttf, bold: true),
              pw.SizedBox(),
              _pdfCell('${AppConstants.rupeeSymbol}$subTotal', ttf,
                  align: pw.TextAlign.right),
            ]),
            // GST
            if (isGstApplied)
              pw.TableRow(children: [
                _pdfCell(
                    'GST (${(AppConstants.gstRate! * 100).toStringAsFixed(1)}%)',
                    ttf),
                pw.SizedBox(),
                _pdfCell(
                    '${AppConstants.rupeeSymbol}${gstAmount.toStringAsFixed(2)}',
                    ttf,
                    align: pw.TextAlign.right),
              ]),
            // Grand Total
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.teal50),
              children: [
                _pdfCell('Grand Total', ttf, bold: true),
                pw.SizedBox(),
                _pdfCell(
                    '${AppConstants.rupeeSymbol}${grandTotal.toStringAsFixed(2)}',
                    ttf,
                    bold: true,
                    align: pw.TextAlign.right),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 24),

        // Payment section
        _pdfSectionTitle('Payment', ttf),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(children: [
              _pdfCell('Method', ttf, bold: true),
              _pdfCell(paymentInfo.method ?? 'Unknown', ttf)
            ]),
            pw.TableRow(children: [
              _pdfCell('Transaction ID', ttf, bold: true),
              _pdfCell(paymentInfo.txnId, ttf)
            ]),
            pw.TableRow(children: [
              _pdfCell('Status', ttf, bold: true),
              _pdfCell(paymentInfo.status, ttf)
            ]),
          ],
        ),

        pw.Spacer(),

        // Footer
        pw.Center(
          child: pw.Text(
            'Thank You! Visit Again',
            style: pw.TextStyle(
                font: ttf, fontSize: 14, fontStyle: pw.FontStyle.italic),
          ),
        ),
      ],
    ),
  );

  return pdf;
}

pw.Widget _pdfSectionTitle(String title, pw.Font font) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(title,
        style: pw.TextStyle(
            font: font, fontSize: 15, fontWeight: pw.FontWeight.bold)),
  );
}

pw.Widget _pdfCell(String text, pw.Font font,
    {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
          font: font, fontWeight: bold ? pw.FontWeight.bold : null),
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
        _pdfCell(
            '${AppConstants.rupeeSymbol}${(price * qty).toStringAsFixed(0)}',
            font,
            align: pw.TextAlign.right),
      ]));
    }
  }
  return rows;
}

({String method, String txnId, String status}) _extractPaymentInfo(
    dynamic response) {

  String method = 'Unknown';
  String txnId = '—';
  String status = 'Unknown';

  print("response : $response");

  if (response is Map) {
    final payu = response['payuResponse'];

    if (payu is Map) {
      // FIRST PRIORITY: PayU response
      method = payu['mode']?.toString() ?? 'Unknown';
      txnId = payu['txnid']?.toString() ?? '—';
      status = (payu['status']?.toString() ?? 'Unknown').toUpperCase();
    } else {
      // FALLBACK: Backend response
      method = response['paymentMethod']?.toString() ?? 'Unknown';
      txnId = response['transactionId']?.toString() ?? '—';
      status = (response['status']?.toString() ?? 'Unknown').toUpperCase();
    }
  }

  return (method: method, txnId: txnId, status: status);
}

Future<bool?> showWhatsappChooser(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Share via',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('WhatsApp'),
              onTap: () => Navigator.pop(context, false),
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('WhatsApp Business'),
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
    },
  );
}

bool _whatsAppTextSent = false;
bool _useBusinessWhatsapp = false;

Future<void> sharePdfViaWhatsApp({
  required String pdfPath,
  required String phone,
  required BuildContext context,
}) async {
  try {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final platform = WhatsappSharePlusPlatform.instance;

    final isWhatsappInstalled = await platform.isWhatsappInstalled();
    final isWhatsappBusinessInstalled =
        await platform.isWhatsappBusinessInstalled();

    if (!isWhatsappInstalled && !isWhatsappBusinessInstalled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Neither WhatsApp nor WhatsApp Business is installed'),
        ),
      );
      return;
    }

    // 🟢 If both installed → ask user
    if (isWhatsappInstalled && isWhatsappBusinessInstalled && !_whatsAppTextSent) {
      final choice = await showWhatsappChooser(context);
      if (choice == null) return;
      _useBusinessWhatsapp = choice;
    } else if (isWhatsappBusinessInstalled && !isWhatsappInstalled) {
      _useBusinessWhatsapp = true;
    } else {
      _useBusinessWhatsapp = false;
    }

    // ───── FIRST CLICK → TEXT ONLY ─────
    if (!_whatsAppTextSent) {
     final  messageText =
        '📎 *Bill Receipt Attached*\n\n'
        'Please find your invoice attached as a PDF.\n'
        'If you have any questions, feel free to contact us.\n\n'
        '🙏 Thank you for your business!';

      if (_useBusinessWhatsapp) {
        await platform.shareToWhatsappBusiness(
          phone: cleanPhone,
          text: messageText,
        );
      } else {
        await platform.shareToWhatsapp(
          phone: cleanPhone,
          text: messageText,
        );
      }

      _whatsAppTextSent = true;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent. Tap again to send the PDF.'),
        ),
      );
      return;
    }

    // ───── SECOND CLICK → PDF ─────
    final pdfMessageText =
        '📎 *Bill Receipt Attached*\n\n'
        'Please find your invoice attached as a PDF.\n'
        'If you have any questions, feel free to contact us.\n\n'
        '🙏 Thank you for your business!';

    if (_useBusinessWhatsapp) {
      await platform.shareImageToWhatsappBusiness(
        phone: cleanPhone,
        imagePath: pdfPath,
        text: pdfMessageText,
      );
    } else {
      await platform.shareImageToWhatsapp(
        phone: cleanPhone,
        imagePath: pdfPath,
        text: pdfMessageText,
      );
    }

    _whatsAppTextSent = false;
  } catch (e) {
    _whatsAppTextSent = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('WhatsApp share failed: $e'),
      ),
    );
  }
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
