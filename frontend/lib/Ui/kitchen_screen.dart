import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/KitchenBloc/bloc.dart';
import '../bloc/KitchenBloc/event.dart';
import '../bloc/KitchenBloc/state.dart';
import '../services/socketService.dart';

class KitchenDashboardScreen extends StatelessWidget {
  const KitchenDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = KitchenDashboardBloc(SocketService());
        return bloc;
      },
      child: const KitchenDashboardView(),
    );
  }
}

class KitchenDashboardView extends StatelessWidget {
  const KitchenDashboardView({super.key});

  Color _getStatusColor(String status) {
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

  String _formatTime(String time) {
    try {
      final dateTime = DateTime.parse(time);
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
    } catch (e) {
      print('Error parsing time: $e, time: $time');
      return 'Invalid Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    return BlocBuilder<KitchenDashboardBloc, KitchenDashboardState>(
      builder: (context, state) {
        final filteredOrders = state.selectedStatusFilter == 'All'
            ? state.orders
            : state.orders.where((order) => order['status'] == state.selectedStatusFilter).toList();
        final newOrders = state.orders.where((order) => order['status'] == 'Pending').toList();

        print('Building UI with orders: ${state.orders.length}, filtered: ${filteredOrders.length}, new: ${newOrders.length}, refreshKey: ${state.refreshKey}');

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(context, screenWidth),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
                vertical: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, screenWidth, filteredOrders.length),
                    const SizedBox(height: 20),
                    _buildFilterRow(context, screenWidth, isTablet),
                    const SizedBox(height: 20),
                    if (newOrders.isNotEmpty) ...[
                      Text(
                        'New Orders',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildOrdersList(context, newOrders, screenWidth, isTablet, isDesktop),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      state.selectedStatusFilter == 'All' ? 'All Orders' : '${state.selectedStatusFilter} Orders',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                                        newOrders.isEmpty ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                      Center(child: Text("No Orders Yet"),),
                    ],) : _buildOrdersList(context, filteredOrders, screenWidth, isTablet, isDesktop)
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, double screenWidth) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              "Kitchen Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1565C0),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            context.read<KitchenDashboardBloc>().add(RefreshDashboard());
          },
        ),
        if (screenWidth > 600)
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, double screenWidth, int orderCount) {
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

  Widget _buildFilterRow(BuildContext context, double screenWidth, bool isTablet) {
    final state = context.read<KitchenDashboardBloc>().state;
    const statusFilters = ['All', 'Pending', 'Preparing', 'Ready'];

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

  Widget _buildOrdersList(BuildContext context, List<Map<String, dynamic>> orders,
      double screenWidth, bool isTablet, bool isDesktop) {
    print('Rendering orders list with ${orders.length} orders: $orders');
    if (isDesktop) {
      return _buildGridLayout(context, orders, screenWidth);
    } else {
      return _buildListLayout(context, orders, screenWidth, isTablet);
    }
  }

  Widget _buildGridLayout(BuildContext context, List<Map<String, dynamic>> orders, double screenWidth) {
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
        return _buildOrderCard(context, orders[index], screenWidth, true);
      },
    );
  }

  Widget _buildListLayout(BuildContext context, List<Map<String, dynamic>> orders,
      double screenWidth, bool isTablet) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildOrderCard(context, orders[index], screenWidth, isTablet);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order,
      double screenWidth, bool isTablet) {
    try {
      final table = order['table'] as String? ?? 'Unknown Table';
      final items = (order['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final status = order['status'] as String? ?? 'Unknown';
      final time = order['time'] as String? ?? '';
      final orderId = order['id'] as String? ?? 'Unknown';
      final total = order['total'] as int? ?? 0;

      Color statusColor = _getStatusColor(status);

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
                  _buildStatusChip(status, statusColor, screenWidth),
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
                        _formatTime(time),
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
                  _buildStatusChip(status, statusColor, screenWidth),
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
                                    '$name ($customization) x$quantity',
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
                      onPressed: () {context.read<KitchenDashboardBloc>().add(
                            UpdateOrderStatusEvent(orderId, 'Served'),
                          );
                          context.read<KitchenDashboardBloc>().add(RefreshDashboard());
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
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error building order card: $e, order: $order');
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error rendering order: $e'),
        ),
      );
    }
  }

  Widget _buildStatusChip(String status, Color statusColor, double screenWidth) {
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
}
