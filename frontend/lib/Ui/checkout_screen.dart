import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:excel/excel.dart';
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

// ───────────────────────────────────────────────
// Professional Analytics Dashboard (Dribbble-inspired)
// ───────────────────────────────────────────────
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:whatsapp_share_plus/whatsapp_share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? dashboardData;
  Map<String, dynamic>? reportData;
  bool isLoading = true;
  String? errorMessage;

  DateTimeRange? selectedRange;
  String paymentFilter = 'All';

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<Uint8List> _generateBillPdf(Map<String, dynamic> bill) async {
    final pdf = pw.Document();

    final billId = bill['billId']?.toString() ?? 'N/A';
    final amount = (bill['amount'] as num? ?? bill['totalAmount'] as num?)
            ?.toStringAsFixed(2) ??
        '0.00';
    final table = bill['table']?.toString() ?? 'N/A';
    final method = bill['paymentMethod']?.toString() ?? 'N/A';
    final mobile = bill['mobile']?.toString() ??
        bill['user']?['mobile']?.toString() ??
        'N/A';

    final dateRaw = bill['date'] ?? bill['updatedAt'];
    final dateStr = dateRaw != null
        ? DateFormat('dd MMM yyyy HH:mm')
            .format(DateTime.tryParse(dateRaw.toString()) ?? DateTime.now())
        : 'N/A';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill Receipt',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              _pdfRow('Bill ID', billId),
              _pdfRow('Date', dateStr),
              _pdfRow('Table', table),
              _pdfRow('Payment Method', method),
              _pdfRow('Mobile', mobile),
              pw.Divider(height: 30),
              pw.Text('Total Amount',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('₹ $amount',
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _shareBillOnWhatsApp(Map<String, dynamic> bill) async {
    final pdfBytes = await _generateBillPdf(bill);
    final fileName = 'bill_${bill['billId']}.pdf';

    if (kIsWeb) {
      await Share.shareXFiles([
        XFile.fromData(pdfBytes, name: fileName, mimeType: 'application/pdf')
      ]);
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([
        XFile.fromData(pdfBytes, name: fileName, mimeType: 'application/pdf')
      ]);
    }
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await Apiservicescheckout.getAnalytics();

      developer.log('DASHBOARD RAW DATA:', name: 'Analytics');
      developer.log(jsonEncode(data), name: 'Analytics');

      if (mounted) {
        setState(() {
          dashboardData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Dashboard fetch error: $e', name: 'Analytics');
      if (mounted) {
        setState(() {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchReportData() async {
    if (selectedRange == null) {
      setState(() => reportData = null);
      return;
    }

    try {
      final data = await Apiservicescheckout.generatePaymentReport(
        startDate: selectedRange!.start.toString(),
        endDate: selectedRange!.end.toString(),
        paymentMethod: paymentFilter == 'All' ? null : paymentFilter,
      );

      developer.log('FILTERED REPORT RAW DATA:', name: 'AnalyticsReport');
      developer.log(jsonEncode(data), name: 'AnalyticsReport');

      if (mounted) {
        setState(() {
          reportData = data;
        });
      }
    } catch (e) {
      developer.log('Report fetch error: $e', name: 'AnalyticsReport');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load filtered report: $e')),
        );
      }
    }
  }

  Future<void> generateAndSaveReport() async {
    final dataSource = reportData ?? dashboardData;
    if (dataSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to export')),
      );
      return;
    }

    try {
      final excel = Excel.createExcel();
      final sheet = excel.sheets.values.first;

      sheet.cell(CellIndex.indexByString('A1')).value =
          TextCellValue('Report Generated: ${DateTime.now()}');
      sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
        bold: true,
        fontFamily: getFontFamily(FontFamily.Calibri),
        fontSize: 14,
      );

      int row = 3;

      // Date Range
      if (selectedRange != null) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue('Date Range');
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
                .value =
            TextCellValue(
                DateFormat('dd-MMM-yyyy').format(selectedRange!.start));
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue('to');
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
                .value =
            TextCellValue(DateFormat('dd-MMM-yyyy').format(selectedRange!.end));
      } else {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue('Date Range');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue('All available data');
      }
      row += 2;

      // Payment Filter
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue('Payment Filter');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(paymentFilter);
      row += 2;

      // ─── Summary Section ─────────────────────────────────────────
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue('Summary');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .cellStyle = CellStyle(
        bold: true,
        fontSize: 13,
        backgroundColorHex: ExcelColor.fromHexString('FFD9EAD3'), // ← FIXED
      );
      row++;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue('Category');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue('Total (₹)');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue('Bill Count');

      for (var col in [0, 1, 2]) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
            .cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: ExcelColor.fromHexString('FFE0F2F1'), // ← FIXED
        );
      }
      row++;

      if (reportData != null) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue('Filtered Period');
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
                .value =
            TextCellValue(
                (reportData!['total'] as num?)?.toStringAsFixed(2) ?? '0.00');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(reportData!['billCount']?.toString() ?? '0');
        row++;

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue('Cash');
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
                .value =
            TextCellValue(
                (reportData!['cash'] as num?)?.toStringAsFixed(2) ?? '0.00');
        row++;

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue('Online');
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
                .value =
            TextCellValue(
                (reportData!['online'] as num?)?.toStringAsFixed(2) ?? '0.00');
        row++;
      } else {
        final today = dataSource['today'] ?? {};
        final month = dataSource['month'] ?? {};

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue('Today');
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
                .value =
            TextCellValue(
                (today['total'] as num?)?.toStringAsFixed(2) ?? '0.00');
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
                .value =
            TextCellValue((today['billCount'] as num?)?.toString() ?? '0');
        row++;

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue('This Month');
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
                .value =
            TextCellValue(
                (month['total'] as num?)?.toStringAsFixed(2) ?? '0.00');
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
                .value =
            TextCellValue((month['billCount'] as num?)?.toString() ?? '0');
        row++;
      }

      row += 2;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue('Pending Bills');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue((dataSource['pendingCount'] ?? 0).toString());
      row += 3;

      final bills = (reportData?['bills'] as List<dynamic>?) ??
          (dataSource['recentBills'] as List<dynamic>?) ??
          [];

      if (bills.isNotEmpty) {
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
                .value =
            TextCellValue(reportData != null
                ? 'Filtered Paid Bills'
                : 'Recent Paid Bills');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .cellStyle = CellStyle(
          bold: true,
          fontSize: 13,
        );
        row++;

        final headers = [
          'Bill ID',
          'Table',
          'Amount (₹)',
          'Method',
          'Date',
          'Mobile'
        ];
        for (int i = 0; i < headers.length; i++) {
          final cell = sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row));
          cell.value = TextCellValue(headers[i]);
          cell.cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: ExcelColor.fromHexString('FFBBDEFB'), // ← FIXED
            textWrapping: TextWrapping.WrapText,
          );
        }
        row++;

        for (var b in bills) {
          final dateStr = b['date'] != null
              ? DateFormat('dd-MMM-yy HH:mm').format(
                  DateTime.tryParse(b['date'].toString()) ?? DateTime.now())
              : 'N/A';

          final mobile = b['mobile']?.toString() ??
              b['user']?['mobile']?.toString() ??
              'N/A';

          final amountStr = (b['amount'] as num? ?? b['totalAmount'] as num?)
                  ?.toStringAsFixed(2) ??
              '0.00';

          final rowData = [
            b['billId']?.toString() ?? 'N/A',
            b['table']?.toString() ?? 'N/A',
            amountStr,
            b['paymentMethod']?.toString() ?? 'Unknown',
            dateStr,
            mobile,
          ];

          for (int i = 0; i < rowData.length; i++) {
            final cell = sheet.cell(
                CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row));
            cell.value = TextCellValue(rowData[i]);
            cell.cellStyle = CellStyle(
              horizontalAlign:
                  i == 2 ? HorizontalAlign.Right : HorizontalAlign.Left,
            );
          }
          row++;
        }
      }

      for (int i = 0; i < 6; i++) {
        sheet.setColumnWidth(i, 18);
      }

      final bytes = excel.save();

      final fileName =
          'analytics_report_${DateTime.now().toIso8601String().split('T')[0]}.xlsx';

      if (kIsWeb) {
        final blob = html.Blob([
          bytes
        ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel report downloaded: $fileName')),
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/$fileName';
        final file = File(path);
        await file.writeAsBytes(bytes!);

        final result = await OpenFilex.open(path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.type == ResultType.done
                ? 'Excel report opened'
                : 'Saved at $path'),
          ),
        );
      }
    } catch (e, stack) {
      developer.log('Excel generation error: $e',
          name: 'Analytics', error: e, stackTrace: stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export Excel report: $e')),
      );
    }
  }

  Future<void> pickDateRange() async {
    final now = DateTime.now();
    final initialStart =
        selectedRange?.start ?? now.subtract(const Duration(days: 30));
    final initialEnd = selectedRange?.end ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        selectedRange = picked;
      });
      await fetchReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 700;
    final padding = isTablet ? 32.0 : 16.0;

    final billsList =
        (reportData?['bills'] as List<dynamic>?)?.isNotEmpty == true
            ? reportData!['bills']
            : (dashboardData?['recentBills'] as List<dynamic>?) ?? [];

    final hasFilteredData = reportData != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Admin Dashboard',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          SizedBox(
            width: 48,
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              // tooltip: 'Refresh Dashboard',
              onPressed: fetchDashboardData,
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              icon: const Icon(Icons.download_rounded),
              // tooltip: 'Download Report (CSV)',
              onPressed: generateAndSaveReport,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : errorMessage != null
              ? RefreshIndicator(
                  onRefresh: fetchDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 80, color: Colors.red.shade400),
                          const SizedBox(height: 24),
                          Text(
                            'Failed to Load Dashboard',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: fetchDashboardData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Filter Report',
                                  style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: pickDateRange,
                                        icon: const Icon(Icons.calendar_month),
                                        label: Text(
                                          selectedRange == null
                                              ? 'Select Date Range'
                                              : '${DateFormat('dd MMM yy').format(selectedRange!.start)} — '
                                                  '${DateFormat('dd MMM yy').format(selectedRange!.end)}',
                                        ),
                                      ),
                                    ),
                                    if (selectedRange != null) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            selectedRange = null;
                                            reportData = null;
                                          });
                                        },
                                        // tooltip: 'Clear date filter',
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: ['All', 'Cash', 'Online'].map((f) {
                                    return ChoiceChip(
                                      label: Text(f),
                                      selected: paymentFilter == f,
                                      selectedColor: Colors.indigo.shade100,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            paymentFilter = f;
                                          });
                                          if (selectedRange != null) {
                                            fetchReportData();
                                          }
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'Overview',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.indigo.shade900,
                          ),
                        ),
                        const SizedBox(height: 24),
LayoutBuilder(
  builder: (context, constraints) {
    final isMobile = constraints.maxWidth < 600;

    return isMobile
        ? Column(
            children: [
              _buildCard(
                'Today Sales',
                (dashboardData?['today']?['total'] as num?)?.toDouble() ?? 0.0,
                (dashboardData?['today']?['billCount'] as num?)?.toInt() ?? 0,
                Colors.teal,
              ),
              const SizedBox(height: 16),
              _buildCard(
                'Monthly Sales',
                (dashboardData?['month']?['total'] as num?)?.toDouble() ?? 0.0,
                (dashboardData?['month']?['billCount'] as num?)?.toInt() ?? 0,
                Colors.deepPurple,
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCard(
                  'Today Sales',
                  (dashboardData?['today']?['total'] as num?)?.toDouble() ?? 0.0,
                  (dashboardData?['today']?['billCount'] as num?)?.toInt() ?? 0,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCard(
                  'Monthly Sales',
                  (dashboardData?['month']?['total'] as num?)?.toDouble() ?? 0.0,
                  (dashboardData?['month']?['billCount'] as num?)?.toInt() ?? 0,
                  Colors.deepPurple,
                ),
              ),
            ],
          );
  },
),

                        const SizedBox(height: 24),

                        Text(
                          'Pending Bills: ${(dashboardData?['pendingCount'] as num?)?.toInt() ?? 0}',
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 32),

                        Text(
                          'Payment Breakdown',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),

                       LayoutBuilder(
  builder: (context, constraints) {
    final isMobile = constraints.maxWidth < 600;

    return isMobile
        ? Column(
            children: [
              _buildPie('Today', dashboardData?['today'] ?? {}),
              const SizedBox(height: 16),
              _buildPie('This Month', dashboardData?['month'] ?? {}),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildPie(
                    'Today', dashboardData?['today'] ?? {}),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPie(
                    'This Month', dashboardData?['month'] ?? {}),
              ),
            ],
          );
  },
),

                        const SizedBox(height: 40),

                        const SizedBox(height: 12),

                        // ────────────────────────────────────────────────
                        // FIXED PAID BILLS SECTION – ONLY THIS PART CHANGED
                        // ────────────────────────────────────────────────
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasFilteredData
                                      ? 'Filtered Paid Bills'
                                      : 'Recent Paid Bills',
                                  style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 400, // you can adjust this value
                                  child: billsList.isEmpty
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 40),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.search_off_rounded,
                                                  size: 64,
                                                  color: Colors.grey.shade400,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  hasFilteredData
                                                      ? 'No paid bills found in selected range & filter'
                                                      : 'No recent paid bills yet',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                if (hasFilteredData) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Try changing date range or payment filter',
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 14,
                                                        color: Colors
                                                            .grey.shade600),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: billsList.length,
                                          itemBuilder: (context, index) {
                                            final b = billsList[index];
                                            final billId =
                                                b['billId']?.toString() ??
                                                    'N/A';
                                            final amount =
                                                (b['amount'] as num? ??
                                                            b['totalAmount']
                                                                as num?)
                                                        ?.toStringAsFixed(2) ??
                                                    '0.00';

                                            final mobile =
                                                b['mobile']?.toString() ??
                                                    b['user']?['mobile']
                                                        ?.toString() ??
                                                    'N/A';

                                            final table =
                                                b['table']?.toString() ?? '?';
                                            final method = b['paymentMethod']
                                                    ?.toString() ??
                                                'Unknown';
                                            final dateRaw =
                                                b['date'] ?? b['updatedAt'];
                                            final dateStr = dateRaw != null
                                                ? DateFormat('dd MMM HH:mm')
                                                    .format(DateTime.tryParse(
                                                            dateRaw
                                                                .toString()) ??
                                                        DateTime.now())
                                                : 'N/A';

                                            return ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor:
                                                    Colors.indigo.shade100,
                                                child: Text(table,
                                                    style: const TextStyle(
                                                        color: Colors.indigo)),
                                              ),
                                              title: Text(
                                                'Bill #$billId • ₹$amount',
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              subtitle: Text(
                                                '$mobile • Table $table • $method',
                                                style: GoogleFonts.poppins(
                                                    color:
                                                        Colors.grey.shade700),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // PDF Share Button
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.picture_as_pdf,
                                                        color: Colors.red),
                                                    tooltip: 'Share PDF',
                                                    onPressed: () async {
                                                      final pdfBytes =
                                                          await _generateBillPdf(
                                                              b); // your PDF generator
                                                      final fileName =
                                                          'bill_$billId.pdf';

                                                      if (kIsWeb) {
                                                        await Share
                                                            .shareXFiles([
                                                          XFile.fromData(
                                                            pdfBytes,
                                                            name: fileName,
                                                            mimeType:
                                                                'application/pdf',
                                                          )
                                                        ]);
                                                      } else {
                                                        final dir =
                                                            await getTemporaryDirectory();
                                                        final file = File(
                                                            '${dir.path}/$fileName');
                                                        await file.writeAsBytes(
                                                            pdfBytes);

                                                        await Share
                                                            .shareXFiles([
                                                          XFile(file.path,
                                                              name: fileName,
                                                              mimeType:
                                                                  'application/pdf')
                                                        ]);
                                                      }
                                                    },
                                                  ),
                                                  // WhatsApp Share Button
                                                  IconButton(
                                                    icon: const FaIcon(
                                                        FontAwesomeIcons
                                                            .whatsapp,
                                                        color: Colors.green),
                                                    tooltip:
                                                        'Share via WhatsApp',
                                                    onPressed: () async {
                                                      final pdfBytes =
                                                          await _generateBillPdf(
                                                              b);
                                                      final fileName =
                                                          'bill_$billId.pdf';
                                                      final dir =
                                                          await getTemporaryDirectory();
                                                      final file = File(
                                                          '${dir.path}/$fileName');
                                                      await file.writeAsBytes(
                                                          pdfBytes);

                                                      await Share.shareXFiles([
                                                        XFile(file.path,
                                                            name: fileName,
                                                            mimeType:
                                                                'application/pdf')
                                                      ]);
                                                    },
                                                  ),
                                                ],
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                            );
                                          },
                                        ),
                                ),
                                const SizedBox(height: 16),
                                if (billsList.isNotEmpty)
                                  Center(
                                    child: ElevatedButton.icon(
                                      onPressed: generateAndSaveReport,
                                      icon: const Icon(Icons.download_rounded),
                                      label: const Text('Export Report (CSV)'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        elevation: 4,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
Widget _buildCard(String title, double amount, int count, Color color) {
  final double screenWidth = MediaQuery.of(context).size.width;
  final bool isMobile = screenWidth < 600;

  return SizedBox(
    width: isMobile ? double.infinity : null,
    child: Card(
      margin: EdgeInsets.zero, // 🔴 removes extra unwanted space
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 20,
          vertical: isMobile ? 12 : 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🔴 prevents extra height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              textScaleFactor: 1.0, // 🔴 prevent system font inflation
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 13 : 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 12),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              textScaleFactor: 1.0,
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 22 : 32,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: isMobile ? 4 : 8),
            Text(
              '$count Bills',
              textScaleFactor: 1.0,
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 11 : 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPie(String title, Map<String, dynamic> data) {
    final cash = (data['cash'] as num?)?.toDouble() ?? 0.0;
    final online = (data['online'] as num?)?.toDouble() ?? 0.0;
    final total = cash + online;

    if (total == 0) {
      return SizedBox(
        height: 200,
        child: Center(
            child: Text('No payments yet',
                style: GoogleFonts.poppins(color: Colors.grey))),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: cash,
                      title:
                          'Cash\n${((cash / total) * 100).toStringAsFixed(0)}%',
                      color: Colors.blue.shade600,
                      radius: 80,
                      titleStyle:
                          const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    PieChartSectionData(
                      value: online,
                      title:
                          'Online\n${((online / total) * 100).toStringAsFixed(0)}%',
                      color: Colors.green.shade600,
                      radius: 80,
                      titleStyle:
                          const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                  centerSpaceRadius: 50,
                  sectionsSpace: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      _showSnackBar('Please enter mobile number', Colors.red);
      return;
    }

    final mobile = controller.text.trim();
    print("Hello : ${mobile}");
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
      await Apiservicescheckout.updateBillStatus(
          billId, 'Paid', method, mobile);
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
        mobile,
        bill['isGstApplied'] as bool? ?? false,
      );

      context
          .read<BillBloc>()
          .add(UpdateBill(billId, 'Paid', paymentMethod: method));
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
  // PDF Generation (unchanged)
  // ───────────────────────────────────────────────
  Future<pw.Document> _buildPdfDocument(
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
                _pdfCell(paymentInfo.method, ttf)
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

  Future<String> generateReceiptPdf(
    dynamic response,
    List<dynamic> orders,
    dynamic user,
    String? mobile,
    bool isGstApplied,
  ) async {
    try {
      final pdf = await _buildPdfDocument(
          response, orders, user, mobile!, isGstApplied);
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
        final path =
            '${dir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
      developer.log('PDF generation failed: $e',
          stackTrace: st, name: 'Checkout');
      _showSnackBar('Could not generate PDF receipt', Colors.orange);
      return '';
    }
  }

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

    final gstAmount = bill['isGstApplied'] == true
        ? subTotal * (AppConstants.gstRate ?? 0.18)
        : 0.0;
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
