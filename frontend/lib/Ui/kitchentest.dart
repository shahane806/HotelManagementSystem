import 'package:flutter/material.dart';

import '../services/socketService.dart';

class KitchenDashboardScreen extends StatefulWidget {
  const KitchenDashboardScreen({super.key});

  @override
  State<KitchenDashboardScreen> createState() => _KitchenDashboardScreenState();
}

class _KitchenDashboardScreenState extends State<KitchenDashboardScreen> {
  final SocketService _socketService = SocketService();
  List<Map<String, dynamic>> orders = [];
  String selectedStatusFilter = 'All';
  final List<String> statusFilters = ['All', 'Pending', 'Preparing', 'Ready', 'Served'];

  @override
  void initState() {
    super.initState();
    // Ensure socket is connected
    if (!_socketService.socket.connected) {
      _socketService.connect();
    }

    // Request initial orders
    _socketService.socket.emit('getOrders');

    // Listen for initial orders
    _socketService.socket.on('initialOrders', (data) {
      setState(() {
        orders = List<Map<String, dynamic>>.from(data);
      });
    });

    // Listen for new orders
    _socketService.socket.on('newOrder', (data) {
      setState(() {
        orders.add(data);
      });
    });

    // Listen for order status updates
    _socketService.socket.on('orderStatusUpdate', (data) {
      setState(() {
        orders = orders.map((order) {
          if (order['id'] == data['orderId']) {
            return {...order, 'status': data['status']};
          }
          return order;
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    // Do not disconnect the socket to preserve connection
    // _socketService.disconnect();
    super.dispose();
  }

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
    final dateTime = DateTime.parse(time);
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    // Filter orders based on selected status
    final filteredOrders = selectedStatusFilter == 'All'
        ? orders
        : orders.where((order) => order['status'] == selectedStatusFilter).toList();

    // New orders are those with status 'Pending'
    final newOrders = orders.where((order) => order['status'] == 'Pending').toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, screenWidth),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
            vertical: 16,
          ),
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
                selectedStatusFilter == 'All' ? 'All Orders' : '$selectedStatusFilter Orders',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildOrdersList(context, filteredOrders, screenWidth, isTablet, isDesktop),
              ),
            ],
          ),
        ),
      ),
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
            _socketService.socket.emit('getOrders');
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
                  color: selectedStatusFilter == status ? Colors.white : Colors.grey[800],
                ),
              ),
              selected: selectedStatusFilter == status,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    selectedStatusFilter = status;
                  });
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
    if (isDesktop) {
      return _buildGridLayout(context, orders, screenWidth);
    } else {
      return _buildListLayout(context, orders, screenWidth, isTablet);
    }
  }

  Widget _buildGridLayout(BuildContext context, List<Map<String, dynamic>> orders, double screenWidth) {
    return GridView.builder(
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
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildOrderCard(context, orders[index], screenWidth, false);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order,
      double screenWidth, bool isGridLayout) {
    final table = order['table'] as String;
    final items = order['items'] as List<dynamic>;
    final status = order['status'] as String;
    final time = order['time'] as String;
    final orderId = order['id'] as String;

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
              size: screenWidth > 600 ? 24 : 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  table,
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
              if (screenWidth > 400) ...[
                const SizedBox(width: 8),
                _buildStatusChip(status, statusColor, screenWidth),
              ],
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
                      overflow: TextOverflow.visible,
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
            horizontal: screenWidth > 600 ? 20 : 16,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order Items",
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item['name']} (${item['customization']}) x${item['quantity']}',
                              style: TextStyle(
                                fontSize: screenWidth > 600 ? 14 : 12,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          Text(
                            '₹${item['price'] * item['quantity']}',
                            style: TextStyle(
                              fontSize: screenWidth > 600 ? 14 : 12,
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Total: ₹${order['total']}',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: statusFilters
                  .where((s) => s != 'All')
                  .map((newStatus) => ElevatedButton(
                        onPressed: () {
                          _socketService.updateOrderStatus(orderId, newStatus);
                          // Emit the status update to ensure TableDashboardScreen receives it
                          _socketService.socket.emit('orderStatusUpdate', {
                            'orderId': orderId,
                            'status': newStatus,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getStatusColor(newStatus).withOpacity(0.1),
                          foregroundColor: _getStatusColor(newStatus),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          newStatus,
                          style: TextStyle(
                            fontSize: screenWidth > 600 ? 14 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color statusColor, double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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