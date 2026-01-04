import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/KitchenBloc/bloc.dart';
import '../bloc/KitchenBloc/event.dart';

  Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.red;
      case 'Preparing':
        return Colors.orange;
      case 'Ready':
        return Colors.green;
      case 'Served':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String formatTime(String time) {
    try {
      final dateTime = DateTime.parse(time);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}  ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
    } catch (e) {
      return 'Invalid Time';
    }
  }

  Widget buildHeader(BuildContext context, double screenWidth, int orderCount) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? 24 : 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Active Orders",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth > 600 ? 18 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$orderCount orders in queue",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: screenWidth > 600 ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.timer_outlined,
              color: Colors.white,
              size: screenWidth > 600 ? 28 : 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFilterRow(BuildContext context, double screenWidth, bool isTablet) {
    final state = context.read<KitchenDashboardBloc>().state;
    const statusFilters = ['All', 'Pending', 'Preparing', 'Ready','Served'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statusFilters.map((status) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                status,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: state.selectedStatusFilter == status ? Colors.white : Colors.grey[800],
                ),
              ),
              selected: state.selectedStatusFilter == status,
              onSelected: (selected) {
                if (selected) {
                  context.read<KitchenDashboardBloc>().add(ChangeFilter(status));
                }
              },
              selectedColor: Colors.indigo,
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildOrdersList(BuildContext context, List<Map<String, dynamic>> orders,
      double screenWidth, bool isTablet, bool isDesktop) {
    if (isDesktop) {
      return buildGridLayout(context, orders, screenWidth);
    } else {
      return buildListLayout(context, orders, screenWidth, isTablet);
    }
  }

  Widget buildGridLayout(BuildContext context, List<Map<String, dynamic>> orders, double screenWidth) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth > 1400 ? 3 : 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return buildOrderCard(context, orders[index], screenWidth, true);
      },
    );
  }

  Widget buildListLayout(BuildContext context, List<Map<String, dynamic>> orders,
      double screenWidth, bool isTablet) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return buildOrderCard(context, orders[index], screenWidth, isTablet);
      },
    );
  }

  Widget buildOrderCard(BuildContext context, Map<String, dynamic> order,
      double screenWidth, bool isTablet) {
    try {
      final table = order['table'] as String? ?? 'Unknown Table';
      final items = (order['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final status = order['status'] as String? ?? 'Unknown';
      final time = order['createdAt'] as String? ?? '';
      final orderId = order['id'] as String? ?? 'Unknown';
      final total = order['total'] as int? ?? 0;

      Color statusColor = getStatusColor(status);

      return Card(
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.table_restaurant,
                color: statusColor,
                size: isTablet ? 24 : 20,
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    table,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 20,),
                if (screenWidth > 400)
                  buildStatusChip(status, statusColor, screenWidth),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        formatTime(time),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (screenWidth <= 400) ...[
                  const SizedBox(height: 8),
                  buildStatusChip(status, statusColor, screenWidth),
                ],
              ],
            ),
            childrenPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: 12,
            ),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: SizedBox(
                  height: 200, // Constrain height to prevent overflow
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order Items",
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (items.isEmpty)
                          Text(
                            'No items available',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ...items.map((item) {
                          final name = item['name'] as String? ?? 'Unknown Item';
                          final customization = item['customization'] as String? ?? 'None';
                          final quantity = item['quantity'] as int? ?? 1;
                          final price = item['price'] as int? ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '$name ($customization) x $quantity',
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 12,
                                      color: Colors.grey[800],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '₹${price * quantity}',
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '₹$total',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (status != 'Pending')
                    ElevatedButton(
                      onPressed: () => context.read<KitchenDashboardBloc>().add(
                            UpdateOrderStatusEvent(orderId, 'Pending'),
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        'Set Pending',
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (status != 'Preparing')
                    ElevatedButton(
                      onPressed: () => context.read<KitchenDashboardBloc>().add(
                            UpdateOrderStatusEvent(orderId, 'Preparing'),
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[50],
                        foregroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        'Set Preparing',
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (status != 'Ready')
                    ElevatedButton(
                      onPressed: () => context.read<KitchenDashboardBloc>().add(
                            UpdateOrderStatusEvent(orderId, 'Ready'),
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[50],
                        foregroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        'Set Ready',
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                 if (status != 'Served')
  ElevatedButton(
    onPressed: () {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Confirm Action'),
            content: const Text('Are you sure you want to set this order as Served?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close dialog
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close dialog

                  context.read<KitchenDashboardBloc>().add(
                    UpdateOrderStatusEvent(orderId, 'Served'),
                  );
                  context.read<KitchenDashboardBloc>().add(
                    RefreshDashboard(),
                  );
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue[50],
      foregroundColor: Colors.blue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    child: Text(
      'Set Served',
      style: TextStyle(
        fontSize: isTablet ? 12 : 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  )

                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error rendering order: $e'),
        ),
      );
    }
  }

  Widget buildStatusChip(String status, Color statusColor, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? 12 : 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: screenWidth > 600 ? 12 : 10,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  

