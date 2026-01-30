// ───────────────────────────────────────────────
// Professional Analytics Dashboard (Dribbble-inspired)
// ───────────────────────────────────────────────
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:universal_html/html.dart' as html;

import '../repositories/bill_pdf.dart';
import '../services/apiServicesCheckout.dart';

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
  String? mobileFilter;

  DateTimeRange? selectedRange;
  String paymentFilter = 'All';

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
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
        mobile: mobileFilter?.trim().isNotEmpty == true
            ? mobileFilter!.trim()
            : null,
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
        // final anchor = html.AnchorElement(href: url)
        //   ..setAttribute('download', fileName)
        //   ..click();
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.type == ResultType.done
                  ? 'Excel report opened'
                  : 'Saved at $path'),
            ),
          );
        }
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
            : (dashboardData?['bills'] as List<dynamic>?) ?? [];

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

                                // ─────────────────────────────────────────────────────────────
                                // NEW: Mobile number filter field + active filter chip
                                // ─────────────────────────────────────────────────────────────
                                const SizedBox(height: 16),
                                TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Customer Mobile',
                                    hintText:
                                        'Enter 10-digit mobile number (optional)',
                                    prefixIcon:
                                        const Icon(Icons.phone_android_rounded),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    suffixIcon: mobileFilter != null &&
                                            mobileFilter!.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear,
                                                color: Colors.redAccent),
                                            onPressed: () {
                                              setState(() {
                                                mobileFilter = null;
                                              });
                                              if (selectedRange != null) {
                                                fetchReportData();
                                              }
                                            },
                                          )
                                        : null,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      mobileFilter = value.trim();
                                    });
                                  },
                                  onSubmitted: (value) {
                                    if (selectedRange != null &&
                                        value.trim().length == 10) {
                                      fetchReportData();
                                    }
                                  },
                                ),

                                const SizedBox(height: 12),

                                // Show active mobile filter as a removable chip
                                if (mobileFilter != null &&
                                    mobileFilter!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Chip(
                                      avatar: const Icon(Icons.phone,
                                          size: 18, color: Colors.indigo),
                                      label: Text(
                                        'Mobile: $mobileFilter',
                                        style: const TextStyle(
                                            color: Colors.indigo),
                                      ),
                                      backgroundColor: Colors.indigo.shade50,
                                      deleteIcon:
                                          const Icon(Icons.close, size: 18),
                                      onDeleted: () {
                                        setState(() {
                                          mobileFilter = null;
                                        });
                                        if (selectedRange != null) {
                                          fetchReportData();
                                        }
                                      },
                                    ),
                                  ),

                                // Optional: Clear all filters button (appears when any filter is active)
                                if (selectedRange != null ||
                                    paymentFilter != 'All' ||
                                    (mobileFilter != null &&
                                        mobileFilter!.isNotEmpty))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.filter_alt_off,
                                            size: 18),
                                        label: const Text('Clear All Filters'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                          side: const BorderSide(
                                              color: Colors.redAccent),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            selectedRange = null;
                                            paymentFilter = 'All';
                                            mobileFilter = null;
                                            reportData = null;
                                          });
                                        },
                                      ),
                                    ),
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
                                        (dashboardData?['today']?['total']
                                                    as num?)
                                                ?.toDouble() ??
                                            0.0,
                                        (dashboardData?['today']?['billCount']
                                                    as num?)
                                                ?.toInt() ??
                                            0,
                                        Colors.teal,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildCard(
                                        'Monthly Sales',
                                        (dashboardData?['month']?['total']
                                                    as num?)
                                                ?.toDouble() ??
                                            0.0,
                                        (dashboardData?['month']?['billCount']
                                                    as num?)
                                                ?.toInt() ??
                                            0,
                                        Colors.deepPurple,
                                      ),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildCard(
                                          'Today Sales',
                                          (dashboardData?['today']?['total']
                                                      as num?)
                                                  ?.toDouble() ??
                                              0.0,
                                          (dashboardData?['today']?['billCount']
                                                      as num?)
                                                  ?.toInt() ??
                                              0,
                                          Colors.teal,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildCard(
                                          'Monthly Sales',
                                          (dashboardData?['month']?['total']
                                                      as num?)
                                                  ?.toDouble() ??
                                              0.0,
                                          (dashboardData?['month']?['billCount']
                                                      as num?)
                                                  ?.toInt() ??
                                              0,
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
                                      _buildPie('Today',
                                          dashboardData?['today'] ?? {}),
                                      const SizedBox(height: 16),
                                      _buildPie('This Month',
                                          dashboardData?['month'] ?? {}),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildPie('Today',
                                            dashboardData?['today'] ?? {}),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildPie('This Month',
                                            dashboardData?['month'] ?? {}),
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
                                            // final dateRaw =
                                            //     b['date'] ?? b['updatedAt'];
                                            // final dateStr = dateRaw != null
                                            //     ? DateFormat('dd MMM HH:mm')
                                            //         .format(DateTime.tryParse(
                                            //                 dateRaw
                                            //                     .toString()) ??
                                            //             DateTime.now())
                                            //     : 'N/A';

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
                                                  // PDF Button
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.picture_as_pdf,
                                                        color: Colors.red),
                                                    tooltip: 'Share PDF',
                                                    onPressed: () async {
                                                      final result =
                                                          await generateReceiptPdf(
                                                        b,
                                                        List<
                                                                Map<String,
                                                                    dynamic>>.from(
                                                            b['orders'] ?? []),
                                                        b['user'] ??
                                                            {
                                                              'fullName':
                                                                  'Guest',
                                                              'mobile': b['mobile']
                                                                      ?.toString() ??
                                                                  'N/A',
                                                            },
                                                        (b['mobile'] ??
                                                                b['user']
                                                                    ?['mobile'])
                                                            ?.toString(),
                                                        b['isGstApplied'] ??
                                                            false,
                                                        context,
                                                      );

                                                      if (!kIsWeb &&
                                                          result.isNotEmpty) {
                                                        await Share.shareXFiles(
                                                          [
                                                            XFile(
                                                              result,
                                                              name:
                                                                  'bill_${b['billId']}.pdf',
                                                              mimeType:
                                                                  'application/pdf',
                                                            ),
                                                          ],
                                                          text:
                                                              'Your bill receipt',
                                                        );
                                                      }
                                                    },
                                                  ),

                                                  // WhatsApp Button
                                                  IconButton(
                                                    icon: const FaIcon(
                                                        FontAwesomeIcons
                                                            .whatsapp,
                                                        color: Colors.green),
                                                    tooltip:
                                                        'Share via WhatsApp',
                                                    onPressed: () async {
                                                      final result =
                                                          await generateReceiptPdf(
                                                        b,
                                                        List<
                                                                Map<String,
                                                                    dynamic>>.from(
                                                            b['orders'] ?? []),
                                                        b['user'] ??
                                                            {
                                                              'fullName':
                                                                  'Guest',
                                                              'mobile': b['mobile']
                                                                      ?.toString() ??
                                                                  'N/A',
                                                            },
                                                        (b['mobile'] ??
                                                                b['user']
                                                                    ?['mobile'])
                                                            ?.toString(),
                                                        b['isGstApplied'] ??
                                                            false,
                                                        context,
                                                      );
                                                      sharePdfViaWhatsApp(
                                                          pdfPath: result,
                                                          phone:
                                                              "+91${b['mobile']}",
                                                          context: context);
                                                      // if (!kIsWeb &&
                                                      //     result.isNotEmpty) {
                                                      //   await Share.shareXFiles(
                                                      //     [
                                                      //       XFile(
                                                      //         result,
                                                      //         name:
                                                      //             'bill_${b['billId']}.pdf',
                                                      //         mimeType:
                                                      //             'application/pdf',
                                                      //       ),
                                                      //     ],
                                                      //     text:
                                                      //         'Your bill receipt',
                                                      //   );
                                                      // }
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
