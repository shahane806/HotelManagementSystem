import 'dart:io';
import 'package:flutter/services.dart' show rootBundle, Uint8List;
import 'package:logging/logging.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../app/constants.dart';
import '../models/order_model.dart';

class ReceiptPdfGenerator {
  static final Logger _logger = Logger('ReceiptPdfGenerator');

  static String _sanitizeText(String input) {
    return input
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

static Future<File?> generateReceipt({
  required List<Order> orders,
  required String userName,
  required String userMobile,
  required String txnId,
  required String amount,
  String paymentMethod = 'Unknown',
  String paymentStatus = 'Success',
  bool isGstApplied = true,
}) async {
  try {
    _logger.info('Generating receipt for transaction: $txnId');

    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final double totalPrice = double.tryParse(amount) ?? 0.0;
    final double gstAmount = isGstApplied ? totalPrice * AppConstants.gstRate : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  AppConstants.companyName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    font: ttf,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  AppConstants.companyAddress,
                  style: pw.TextStyle(fontSize: 12, font: ttf),
                ),
                if (isGstApplied)
                  pw.Text(
                    'GSTIN: ${AppConstants.merchantGstNumber}',
                    style: pw.TextStyle(fontSize: 12, font: ttf),
                  ),
                pw.Text(
                  'Merchant: ${_sanitizeText(userName)}',
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
                  'Date: ${DateTime.now().toIso8601String().split("T").first}',
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
          pw.Text('Name: ${_sanitizeText(userName)}', style: pw.TextStyle(font: ttf)),
          pw.Text('Mobile: $userMobile', style: pw.TextStyle(font: ttf)),
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
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blue100),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Customization', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf))),
                ],
              ),
              ...orders.expand((order) => [
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Table: ${order.table} (${order.status})', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                      ],
                    ),
                    ...order.items.entries.map((entry) => pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_sanitizeText(entry.key.menuItem.name), style: pw.TextStyle(font: ttf))),
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_sanitizeText(entry.key.customization), style: pw.TextStyle(font: ttf))),
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${entry.value}', style: pw.TextStyle(font: ttf))),
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${AppConstants.rupeeSymbol}${(entry.key.menuItem.price * entry.value).toStringAsFixed(0)}', style: pw.TextStyle(font: ttf))),
                          ],
                        )),
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.teal100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Subtotal', style: pw.TextStyle(font: ttf))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${AppConstants.rupeeSymbol}${order.total.toStringAsFixed(0)}', style: pw.TextStyle(font: ttf))),
                      ],
                    ),
                  ]).toList(),
              if (isGstApplied)
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('GST (${(AppConstants.gstRate * 100).toStringAsFixed(0)}%)', style: pw.TextStyle(font: ttf))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${AppConstants.rupeeSymbol}${gstAmount.toStringAsFixed(0)}', style: pw.TextStyle(font: ttf))),
                  ],
                ),
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blue100),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${AppConstants.rupeeSymbol}${totalPrice.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf))),
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
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Field', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf))),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Payment Method', style: pw.TextStyle(font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_sanitizeText(paymentMethod), style: pw.TextStyle(font: ttf))),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Transaction ID', style: pw.TextStyle(font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_sanitizeText(txnId), style: pw.TextStyle(font: ttf))),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Payment Status', style: pw.TextStyle(font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_sanitizeText(paymentStatus), style: pw.TextStyle(font: ttf))),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'Thank you for dining with us!',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: ttf),
                ),
                pw.Text(
                  'Come visit us again at ${AppConstants.companyName}',
                  style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, font: ttf),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final Uint8List pdfBytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/receipt_$txnId.pdf';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes, flush: true);

    _logger.info('Receipt saved at: ${file.path}');
    await OpenFilex.open(file.path);
    return file;
  } catch (e, st) {
    _logger.severe('Error generating receipt $txnId', e, st);
    return null;
  }
}

}