import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/services/apiServicesCheckout.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import '../bloc/MenuUtility/bloc.dart';
import '../bloc/MenuUtility/event.dart';
import '../bloc/MenuUtility/state.dart';
import '../bloc/OrderBloc/bloc.dart';
import '../bloc/OrderBloc/event.dart';
import '../bloc/OrderBloc/state.dart';
import '../bloc/TableUtility/bloc.dart';
import '../bloc/TableUtility/event.dart';
import '../bloc/TableUtility/state.dart';
import '../models/bill_model.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../models/menu_model.dart';
import '../models/user_model.dart';
import '../services/socketService.dart';
import '../widgets/table_widgets.dart';

class TableDashboardScreen extends StatefulWidget {
  const TableDashboardScreen({super.key});

  @override
  State<TableDashboardScreen> createState() => _TableDashboardScreenState();
}

class _TableDashboardScreenState extends State<TableDashboardScreen>
    with TickerProviderStateMixin {
  String? selectedTable;
  late AnimationController _animationController;
  int _selectedIndex = 0;
  final Map<MenuItem, String> selectedOptions = {};
  List<String> _categories = [];
  List<MenuItem> _menuItems = [];
  bool _isInitialLoad = true;
  bool _isVegFilter = true;
  final UserModel _user = UserModel(
    userId: '0001',
    fullName: 'John Doe',
    email: 'john.doe@example.com',
    mobile: '9876543210',
    aadhaarNumber: '',
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    SocketService().connect();
    SocketService().socket.on('orderUpdated', (data) {
      final map = Map<String, dynamic>.from(data);
      final orderId = map['orderId'] as String?;
      final status = map['status'] as String?;

      if (orderId == null || status == null) return;

      // Drop any terminal update – the BLoC will handle removal
      if ({'Paid', 'Completed', 'Cancelled'}.contains(status)) {
        context.read<OrdersBloc>().add(RemoveRecentOrder(orderId));
        return;
      }

      context.read<OrdersBloc>().add(UpdateOrderStatus(orderId, status));
    });

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<TablesBloc>().add(FetchTables());
    //   context.read<MenusBloc>().add(FetchMenus());
    // });
  }

  @override
  void dispose() {
    _animationController.dispose();
    SocketService().disconnect();
    super.dispose();
  }

  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _showRecentOrders(context);
    } else if (index == 1) {
      _showOrderBottomSheet(context);
    }
  }

  Future<void> _generateBillPDF(List<Order> orders) async {
    if (!mounted || orders.isEmpty) return;

    // Construct the Bill object
    final bill = Bill(
      billId: const Uuid().v4(),
      table: orders.first.table,
      totalAmount: orders.fold<double>(
        0,
        (sum, order) => sum + order.total.toDouble(),
      ),
      orders: orders,
      user: _user,
      isGstApplied: true,
    );

    // Call API to pay bill
    await Apiservicescheckout.payBill(bill);

    // Emit via socket
    SocketService().payBill({
      'billId': bill.billId,
      'table': bill.table,
      'totalAmount': bill.totalAmount,
      'orders': bill.orders.map((o) => o.toJson()).toList(),
      'user': bill.user.toJson(),
      'isGstApplied': bill.isGstApplied,
    });
    // 5. **REMOVE PAID ORDERS FROM RECENT LIST**
    final bloc = context.read<OrdersBloc>();
    for (final order in orders) {
      bloc.add(RemoveRecentOrder(order.id));
    }

    // 6. (Optional) clear current-order items that belong to the same table
    final currentOrder = context.read<OrdersBloc>().state.currentOrder;
    for (final entry in currentOrder.entries) {
      final orderItem = entry.key;
      final qty = entry.value;
      for (int i = 0; i < qty; i++) {
        bloc.add(RemoveOrderItem(orderItem));
      }
    }
    for (final order in orders) {
      for (final entry in order.items.entries) {
        final orderItem = entry.key;
        final quantity = entry.value;
        for (int i = 0; i < quantity; i++) {
          bloc.add(RemoveOrderItem(orderItem));
        }
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Go to counter for bill.'),
        backgroundColor: Colors.blue,
      ),
    );
    // // Navigate to BuyPage
    // await Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => BuyPage(
    //       orders: orders,
    //       user: _user,
    //       isGstApplied: true,
    //     ),
    //   ),
    // );
  }

  void _showRecentOrders(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_ios,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Orders',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 22 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'View past orders and their status',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isTablet ? 13 : 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isTablet ? 20 : 12),
                          child: BlocBuilder<OrdersBloc, OrdersState>(
                            builder: (context, state) {
                              if (state.status == OrdersStatus.error) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        state.errorMessage ??
                                            'Failed to load orders',
                                        style: TextStyle(
                                          fontSize: isTablet ? 15 : 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: () => context
                                            .read<OrdersBloc>()
                                            .add(const FetchRecentOrders()),
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              final recentOrders = state.recentOrders;
                              final Map<String, List<Order>> groupedOrders = {};
                              for (var order in recentOrders) {
                                groupedOrders
                                    .putIfAbsent(order.table, () => [])
                                    .add(order);
                              }
                              final totalAmount = recentOrders.fold<int>(
                                  0, (sum, order) => sum + order.total);
                              return Column(
                                children: [
                                  Expanded(
                                    child: groupedOrders.isEmpty
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.history_outlined,
                                                  size: isTablet ? 56 : 40,
                                                  color: Colors.grey[400],
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'No recent orders available',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isTablet ? 15 : 13,
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Place an order to see it here',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isTablet ? 11 : 10,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.separated(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemCount: groupedOrders.length,
                                            separatorBuilder:
                                                (context, index) =>
                                                    const SizedBox(height: 12),
                                            itemBuilder: (context, index) {
                                              final table = groupedOrders.keys
                                                  .elementAt(index);
                                              final orders =
                                                  groupedOrders[table]!;
                                              final tableTotal =
                                                  orders.fold<int>(
                                                      0,
                                                      (sum, order) =>
                                                          sum + order.total);
                                              final bool allServed =
                                                  orders.every((order) =>
                                                      order.status == 'Served');
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.05),
                                                      blurRadius: 8,
                                                      offset:
                                                          const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: ExpansionTile(
                                                  tilePadding:
                                                      EdgeInsets.symmetric(
                                                    horizontal:
                                                        isTablet ? 16 : 12,
                                                    vertical: isTablet ? 8 : 6,
                                                  ),
                                                  childrenPadding:
                                                      EdgeInsets.symmetric(
                                                    horizontal:
                                                        isTablet ? 16 : 12,
                                                    vertical: isTablet ? 8 : 6,
                                                  ),
                                                  title: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Table: $table',
                                                        style: TextStyle(
                                                          fontSize: isTablet
                                                              ? 16
                                                              : 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: const Color(
                                                              0xFF2D3748),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[100],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          '₹$tableTotal',
                                                          style: TextStyle(
                                                            fontSize: isTablet
                                                                ? 14
                                                                : 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .green[600],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  children: [
                                                    ...orders
                                                        .asMap()
                                                        .entries
                                                        .map((entry) {
                                                      final orderIndex =
                                                          entry.key;
                                                      final order = entry.value;
                                                      return Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          vertical:
                                                              isTablet ? 8 : 6,
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  'Order #${orderIndex + 1}',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        isTablet
                                                                            ? 14
                                                                            : 12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: const Color(
                                                                        0xFF2D3748),
                                                                  ),
                                                                ),
                                                                Container(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: getStatusColor(order
                                                                            .status)
                                                                        .withOpacity(
                                                                            0.1),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                  ),
                                                                  child: Text(
                                                                    order
                                                                        .status,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          isTablet
                                                                              ? 12
                                                                              : 10,
                                                                      color: getStatusColor(
                                                                          order
                                                                              .status),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                                height: 6),
                                                            ...order
                                                                .items.entries
                                                                .map(
                                                                    (itemEntry) {
                                                              return Padding(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                  vertical:
                                                                      isTablet
                                                                          ? 6
                                                                          : 4,
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    Container(
                                                                      width: isTablet
                                                                          ? 36
                                                                          : 28,
                                                                      height: isTablet
                                                                          ? 36
                                                                          : 28,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .indigo
                                                                            .withOpacity(0.1),
                                                                        borderRadius:
                                                                            BorderRadius.circular(6),
                                                                      ),
                                                                      child:
                                                                          Center(
                                                                        child:
                                                                            Text(
                                                                          itemEntry
                                                                              .key
                                                                              .menuItem
                                                                              .image,
                                                                          style:
                                                                              TextStyle(fontSize: isTablet ? 14 : 12),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                        width: isTablet
                                                                            ? 10
                                                                            : 8),
                                                                    Expanded(
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Text(
                                                                            '${itemEntry.key.menuItem.name} (${itemEntry.key.customization})',
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: isTablet ? 13 : 11,
                                                                              fontWeight: FontWeight.w600,
                                                                              color: const Color(0xFF2D3748),
                                                                            ),
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                          Text(
                                                                            '₹${itemEntry.key.menuItem.price} × ${itemEntry.value}',
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: isTablet ? 11 : 10,
                                                                              color: Colors.grey[600],
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }).toList(),
                                                            const Divider(),
                                                          ],
                                                        ),
                                                      );
                                                    }).toList(),
                                                    Padding(
                                                      padding: EdgeInsets.all(
                                                          isTablet ? 12 : 8),
                                                      child: SizedBox(
                                                        width: double.infinity,
                                                        height:
                                                            isTablet ? 40 : 36,
                                                        child:
                                                            ElevatedButton.icon(
                                                          onPressed: allServed
                                                              ? () =>
                                                                  _generateBillPDF(
                                                                      orders)
                                                              : null,
                                                          icon: const Icon(
                                                              Icons.receipt,
                                                              color:
                                                                  Colors.white,
                                                              size: 18),
                                                          label: Text(
                                                            'Proceed to Payment',
                                                            style: TextStyle(
                                                              fontSize: isTablet
                                                                  ? 13
                                                                  : 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors.green,
                                                            foregroundColor:
                                                                Colors.white,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            elevation: 1,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  if (recentOrders.isNotEmpty)
                                    Padding(
                                      padding:
                                          EdgeInsets.all(isTablet ? 20 : 16),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Total All Orders:',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isTablet ? 16 : 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        const Color(0xFF2D3748),
                                                  ),
                                                ),
                                                Text(
                                                  '₹$totalAmount',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isTablet ? 16 : 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            height: isTablet ? 48 : 40,
                                            child: ElevatedButton.icon(
                                              onPressed: recentOrders.every(
                                                      (order) =>
                                                          order.status ==
                                                          'Served')
                                                  ? () => _generateBillPDF(
                                                      recentOrders)
                                                  : null,
                                              icon: const Icon(Icons.receipt,
                                                  color: Colors.white,
                                                  size: 20),
                                              label: Text(
                                                'Proceed to Payment (All Tables)',
                                                style: TextStyle(
                                                  fontSize: isTablet ? 15 : 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                elevation: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 80),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return BlocListener<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state.status == OrdersStatus.error && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to process order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavBarTapped,
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.history, size: isTablet ? 22 : 20),
              label: 'Recent Order',
            ),
            BottomNavigationBarItem(
              icon: BlocSelector<OrdersBloc, OrdersState, Map<OrderItem, int>>(
                selector: (state) => state.currentOrder,
                builder: (context, currentOrder) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.restaurant, size: isTablet ? 22 : 20),
                      if (currentOrder.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${currentOrder.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              label: 'Current Order',
            ),
          ],
          selectedLabelStyle: TextStyle(
              fontSize: isTablet ? 13 : 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: isTablet ? 12 : 10),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, isTablet),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 20 : 12),
                        child: _buildMenuSection(context, isTablet),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Table Orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 22 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage table orders and menu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isTablet ? 13 : 11,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isVegFilter = !_isVegFilter;
                    final menusState = context.read<MenusBloc>().state;
                    if (menusState is MenusLoaded) {
                      _menuItems =
                          getMenuItemsFromMenus(menusState.menus, _isVegFilter);
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12 : 10,
                      vertical: isTablet ? 6 : 4),
                  decoration: BoxDecoration(
                    color: _isVegFilter
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    border: Border.all(
                      color: _isVegFilter ? Colors.green : Colors.red,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isVegFilter ? Icons.eco : Icons.dinner_dining,
                        color: _isVegFilter ? Colors.green : Colors.red,
                        size: isTablet ? 20 : 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isVegFilter ? 'Veg' : 'Non-Veg',
                        style: TextStyle(
                          color: _isVegFilter ? Colors.green : Colors.red,
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchMenuScreen(
                        menuItems: _menuItems,
                        isVegFilter: _isVegFilter,
                        selectedOptions: selectedOptions,
                        animationController: _animationController,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 24,
                ),
                padding: EdgeInsets.all(isTablet ? 8 : 6),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, bool isTablet) {
    return BlocListener<MenusBloc, MenusState>(
      listener: (context, state) {
        if (state is MenusLoaded) {
          setState(() {
            _categories = state.menus.map((menu) => menu.name).toSet().toList();
            _menuItems = getMenuItemsFromMenus(state.menus, _isVegFilter);
            _isInitialLoad = false;
          });
        } else if (state is MenusError) {
          developer.log('MenusBloc error: ${state.message}',
              name: 'TableDashboardScreen');
        }
      },
      child: BlocBuilder<MenusBloc, MenusState>(
        builder: (context, state) {
          if (_isInitialLoad && state is MenusLoading) {
            return _buildShimmerMenu(isTablet);
          } else if (state is MenusError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: isTablet ? 56 : 40,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message ?? 'Failed to load menus',
                    style: TextStyle(
                      fontSize: isTablet ? 15 : 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        context.read<MenusBloc>().add(FetchMenus()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return BlocSelector<TablesBloc, TablesState, TablesState>(
            selector: (state) => state,
            builder: (context, tableState) {
              if (tableState is TablesLoaded) {
                final tableItems = tableState.tables
                    .expand((table) => table.utilityItems)
                    .toList();
                if (tableItems.isEmpty) {
                  return const Center(child: Text('No table items available'));
                }
                if (selectedTable == null && tableItems.isNotEmpty) {
                  selectedTable = tableItems[0].name;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTableSelector(isTablet, tableItems),
                    SizedBox(height: isTablet ? 16 : 12),
                    Row(
                      children: [
                        Icon(Icons.restaurant_menu,
                            color: Colors.indigo, size: isTablet ? 22 : 18),
                        const SizedBox(width: 6),
                        Text(
                          'Menu Items',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 10 : 6),
                    Expanded(
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isTablet ? 2 : 1,
                          childAspectRatio: isTablet ? 2.4 : 3.4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: _menuItems.length,
                        itemBuilder: (context, index) {
                          final item = _menuItems[index];
                          return _buildMenuItemCard(item, isTablet);
                        },
                      ),
                    ),
                  ],
                );
              } else if (tableState is TablesError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tableState.message),
                      TextButton(
                        onPressed: () =>
                            context.read<TablesBloc>().add(FetchTables()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              return _buildShimmerMenu(isTablet);
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmerMenu(bool isTablet) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 14 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 20 : 18,
                  height: isTablet ? 20 : 18,
                  color: Colors.grey[300],
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Container(
                  width: 100,
                  height: isTablet ? 16 : 14,
                  color: Colors.grey[300],
                ),
                const Spacer(),
                Container(
                  width: isTablet ? 120 : 100,
                  height: isTablet ? 32 : 28,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Row(
            children: [
              Container(
                width: isTablet ? 22 : 18,
                height: isTablet ? 22 : 18,
                color: Colors.grey[300],
              ),
              const SizedBox(width: 6),
              Container(
                width: 100,
                height: isTablet ? 18 : 16,
                color: Colors.grey[300],
              ),
            ],
          ),
          SizedBox(height: isTablet ? 10 : 6),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 2 : 1,
                childAspectRatio: isTablet ? 2.4 : 3.4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 12 : 10),
                    child: Row(
                      children: [
                        Container(
                          width: isTablet ? 50 : 40,
                          height: isTablet ? 50 : 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                height: isTablet ? 15 : 13,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 3),
                              Container(
                                width: 80,
                                height: isTablet ? 11 : 10,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 3),
                              Container(
                                width: 60,
                                height: isTablet ? 15 : 13,
                                color: Colors.grey[300],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.read<OrdersBloc>().add(AddOrderItem(
                  OrderItem(
                    menuItem: item,
                    customization: selectedOptions[item] ?? 'Medium',
                  ),
                ));
            _animationController
                .forward()
                .then((_) => _animationController.reverse());
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 12 : 10),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 50 : 40,
                  height: isTablet ? 50 : 40,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      item.image,
                      style: TextStyle(fontSize: isTablet ? 20 : 18),
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 12 : 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: isTablet ? 15 : 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3748),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.category,
                            style: TextStyle(
                              fontSize: isTablet ? 11 : 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '₹${item.price}',
                            style: TextStyle(
                              fontSize: isTablet ? 15 : 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: SizedBox(
                              width: isTablet ? 100 : 80,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: Colors.indigo[700]!, width: 1.0),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: DropdownButton<String>(
                                  value: selectedOptions[item] ?? 'Medium',
                                  items: ['Spicy', 'Less Spicy', 'Medium']
                                      .map((option) => DropdownMenuItem<String>(
                                            value: option,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              child: Text(
                                                option,
                                                style: TextStyle(
                                                  fontSize: isTablet ? 12 : 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.indigo[700],
                                                ),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedOptions[item] = value;
                                      });
                                    }
                                  },
                                  underline: const SizedBox(),
                                  icon: Icon(Icons.arrow_drop_down,
                                      color: Colors.indigo[700], size: 18),
                                  isExpanded: true,
                                  style: TextStyle(
                                    fontSize: isTablet ? 12 : 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo[700],
                                  ),
                                  dropdownColor: Colors.white,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                        ],
                      ),
                    ],
                  ),
                ),
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.2)
                      .animate(_animationController),
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 10 : 6),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: isTablet ? 18 : 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderBottomSheet(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 12 : 10),
                Row(
                  children: [
                    Icon(Icons.restaurant,
                        color: Colors.indigo, size: isTablet ? 22 : 18),
                    const SizedBox(width: 6),
                    Text(
                      'Current Order',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    const Spacer(),
                    BlocSelector<OrdersBloc, OrdersState, Map<OrderItem, int>>(
                      selector: (state) => state.currentOrder,
                      builder: (context, currentOrder) {
                        if (currentOrder.isNotEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${currentOrder.length} items',
                              style: TextStyle(
                                color: Colors.indigo,
                                fontSize: isTablet ? 11 : 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 12 : 10),
                Expanded(
                  child: BlocSelector<OrdersBloc, OrdersState,
                      Map<OrderItem, int>>(
                    selector: (state) => state.currentOrder,
                    builder: (context, order) {
                      if (order.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_outlined,
                                size: isTablet ? 56 : 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No items added',
                                style: TextStyle(
                                  fontSize: isTablet ? 15 : 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Start adding items from menu',
                                style: TextStyle(
                                  fontSize: isTablet ? 11 : 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: order.entries.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = order.entries.elementAt(index);
                          return _buildOrderItem(entry, isTablet);
                        },
                      );
                    },
                  ),
                ),
                BlocSelector<OrdersBloc, OrdersState, Map<OrderItem, int>>(
                  selector: (state) => state.currentOrder,
                  builder: (context, currentOrder) {
                    if (currentOrder.isNotEmpty) {
                      return Column(
                        children: [
                          const Divider(thickness: 1.5),
                          SizedBox(height: isTablet ? 10 : 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount:',
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D3748),
                                ),
                              ),
                              Text(
                                '₹${getTotalPrice(currentOrder)}',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 12 : 10),
                          SizedBox(
                            width: double.infinity,
                            height: isTablet ? 48 : 40,
                            child: ElevatedButton.icon(
                              onPressed: () => _placeOrder(context),
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.white, size: 20),
                              label: Text(
                                'Place Order',
                                style: TextStyle(
                                  fontSize: isTablet ? 15 : 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 1,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(MapEntry<OrderItem, int> entry, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 10 : 6),
      child: Row(
        children: [
          Container(
            width: isTablet ? 36 : 28,
            height: isTablet ? 36 : 28,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                entry.key.menuItem.image,
                style: TextStyle(fontSize: isTablet ? 14 : 12),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 10 : 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key.menuItem.name} (${entry.key.customization})',
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${entry.key.menuItem.price} × ${entry.value}',
                  style: TextStyle(
                    fontSize: isTablet ? 11 : 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<OrdersBloc>().add(RemoveOrderItem(entry.key));
                },
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 6 : 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: isTablet ? 14 : 12,
                    color: Colors.red,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 10),
                child: Text(
                  '${entry.value}',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<OrdersBloc>().add(AddOrderItem(entry.key));
                },
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 6 : 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.add,
                    size: isTablet ? 14 : 12,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableSelector(bool isTablet, List<TableItem> tableItems) {
    return BlocSelector<TablesBloc, TablesState, TablesState>(
      selector: (state) => state,
      builder: (context, tableState) {
        if (tableState is TablesLoaded) {
          final tableItems =
              tableState.tables.expand((table) => table.utilityItems).toList();
          if (tableItems.isEmpty) {
            return const Center(child: Text('No table items available'));
          }
          if (selectedTable == null && tableItems.isNotEmpty) {
            selectedTable = tableItems[0].name;
          }
          return Container(
            padding: EdgeInsets.all(isTablet ? 14 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.table_restaurant,
                    color: Colors.indigo, size: isTablet ? 20 : 18),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Select Table:',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                        height: MediaQuery.of(context).size.height,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(isTablet ? 24 : 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Select a Table',
                                    style: TextStyle(
                                      fontSize: isTablet ? 20 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white, size: 28),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 20 : 12),
                                  child: GridView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isTablet ? 2 : 1,
                                      childAspectRatio: isTablet ? 2.7 : 3.7,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                    ),
                                    itemCount: tableItems.length,
                                    itemBuilder: (context, index) {
                                      final tableItem = tableItems[index];
                                      return _buildTableItemCard(
                                          tableItem, isTablet);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedTable ?? 'Select a table',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.keyboard_arrow_down,
                            color: Colors.indigo, size: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (tableState is TablesError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tableState.message),
                TextButton(
                  onPressed: () =>
                      context.read<TablesBloc>().add(FetchTables()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return _buildShimmerMenu(isTablet);
      },
    );
  }

  Widget _buildTableItemCard(TableItem tableItem, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => selectedTable = tableItem.name);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 14 : 12),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 56 : 48,
                  height: isTablet ? 56 : 48,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '🪑',
                      style: TextStyle(fontSize: isTablet ? 22 : 20),
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 14 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tableItem.name,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Seats: ${tableItem.count}',
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _placeOrder(BuildContext context) async {
    if (selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a table')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final ordersBloc = context.read<OrdersBloc>();
    final currentState = ordersBloc.state;

    if (currentState.currentOrder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items in the order')),
      );
      return;
    }

    final total = getTotalPrice(currentState.currentOrder);
    final orderId = const Uuid().v4();

    final orderData = {
      'id': orderId,
      'table': selectedTable,
      'items': currentState.currentOrder.entries
          .map((entry) => {
                'name': entry.key.menuItem.name,
                'customization': entry.key.customization,
                'quantity': entry.value,
                'price': entry.key.menuItem.price,
              })
          .toList(),
      'total': total,
      'status': 'Pending',
      'time': DateTime.now().toIso8601String(),
    };

    try {
      SocketService().placeOrder(orderData);
      ordersBloc.add(PlaceOrder(orderId, selectedTable!));

      // final order = Order(
      //   id: orderId,
      //   table: selectedTable!,
      //   items: currentState.currentOrder,
      //   total: total,
      //   status: 'Pending',
      //   timestamp: DateTime.now(),
      // );

      setState(() {
        selectedOptions.clear();
      });

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Order Confirmed',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your order for $selectedTable has been successfully placed!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],
                          ),
                        ),
                        Text(
                          '₹$total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _showRecentOrders(context);
                        },
                        child: Text(
                          'View Recent Orders',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.indigo[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      developer.log('Error sending order via socket: $e',
          name: 'TableDashboardScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send order to server')),
        );
      }
    }
  }
}

class SearchMenuScreen extends StatefulWidget {
  final List<MenuItem> menuItems;
  final bool isVegFilter;
  final Map<MenuItem, String> selectedOptions;
  final AnimationController animationController;

  const SearchMenuScreen({
    super.key,
    required this.menuItems,
    required this.isVegFilter,
    required this.selectedOptions,
    required this.animationController,
  });

  @override
  State<SearchMenuScreen> createState() => _SearchMenuScreenState();
}

class _SearchMenuScreenState extends State<SearchMenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MenuItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.menuItems;
    _searchController.addListener(_filterMenuItems);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterMenuItems);
    _searchController.dispose();
    super.dispose();
  }

  void _filterMenuItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.menuItems.where((item) {
        final matchesFilter =
            widget.isVegFilter ? item.type == 'Veg' : item.type == 'Non-Veg';
        final matchesQuery = item.name.toLowerCase().contains(query);
        return matchesFilter && matchesQuery;
      }).toList();
    });
  }

  Widget _buildMenuItemCard(MenuItem item, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.read<OrdersBloc>().add(AddOrderItem(
                  OrderItem(
                    menuItem: item,
                    customization: widget.selectedOptions[item] ?? 'Medium',
                  ),
                ));
            widget.animationController
                .forward()
                .then((_) => widget.animationController.reverse());
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 12 : 10),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 50 : 40,
                  height: isTablet ? 50 : 40,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      item.image,
                      style: TextStyle(fontSize: isTablet ? 20 : 18),
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 12 : 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: isTablet ? 15 : 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3748),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.category,
                            style: TextStyle(
                              fontSize: isTablet ? 11 : 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '₹${item.price}',
                            style: TextStyle(
                              fontSize: isTablet ? 15 : 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: SizedBox(
                              width: isTablet ? 100 : 80,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: Colors.indigo[700]!, width: 1.0),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: DropdownButton<String>(
                                  value:
                                      widget.selectedOptions[item] ?? 'Medium',
                                  items: ['Spicy', 'Less Spicy', 'Medium']
                                      .map((option) => DropdownMenuItem<String>(
                                            value: option,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              child: Text(
                                                option,
                                                style: TextStyle(
                                                  fontSize: isTablet ? 12 : 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.indigo[700],
                                                ),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        widget.selectedOptions[item] = value;
                                      });
                                    }
                                  },
                                  underline: const SizedBox(),
                                  icon: Icon(Icons.arrow_drop_down,
                                      color: Colors.indigo[700], size: 18),
                                  isExpanded: true,
                                  style: TextStyle(
                                    fontSize: isTablet ? 12 : 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo[700],
                                  ),
                                  dropdownColor: Colors.white,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                        ],
                      ),
                    ],
                  ),
                ),
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.2)
                      .animate(widget.animationController),
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 10 : 6),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: isTablet ? 18 : 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search Menu',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 20 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search menu items...',
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.indigo),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        SizedBox(height: isTablet ? 16 : 12),
                        Row(
                          children: [
                            Icon(Icons.restaurant_menu,
                                color: Colors.indigo, size: isTablet ? 22 : 18),
                            const SizedBox(width: 6),
                            Text(
                              'Search Results',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 10 : 6),
                        Expanded(
                          child: _filteredItems.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: isTablet ? 56 : 40,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No items found',
                                        style: TextStyle(
                                          fontSize: isTablet ? 15 : 13,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Try a different search term',
                                        style: TextStyle(
                                          fontSize: isTablet ? 11 : 10,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isTablet ? 2 : 1,
                                    childAspectRatio: isTablet ? 2.4 : 3.4,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                  ),
                                  itemCount: _filteredItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _filteredItems[index];
                                    return _buildMenuItemCard(item, isTablet);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
