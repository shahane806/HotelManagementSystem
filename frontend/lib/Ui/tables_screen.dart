import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TableDashboardScreen extends StatefulWidget {
  const TableDashboardScreen({super.key});

  @override
  State<TableDashboardScreen> createState() => _TableDashboardScreenState();
}

class _TableDashboardScreenState extends State<TableDashboardScreen>
    with TickerProviderStateMixin {
  String selectedTable = 'Table 1';
  late AnimationController _animationController;
  int _selectedIndex = 0; // Track selected BottomNavigationBar item

  final List<String> tables = [
    'Table 1', 'Table 2', 'Table 3', 'Table 4', 'Table 5',
    'Table 6', 'Table 7', 'Table 8', 'Table 9', 'Table 10',
  ];

  final List<MenuItem> menuItems = [
    MenuItem(name: 'Paneer Butter Masala', price: 180, category: 'Main Course', image: '🍛'),
    MenuItem(name: 'Chicken Biryani', price: 220, category: 'Main Course', image: '🍚'),
    MenuItem(name: 'Veg Fried Rice', price: 150, category: 'Main Course', image: '🍳'),
    MenuItem(name: 'Masala Dosa', price: 100, category: 'South Indian', image: '🥞'),
    MenuItem(name: 'Cold Coffee', price: 80, category: 'Beverages', image: '☕'),
    MenuItem(name: 'Ice Cream', price: 70, category: 'Desserts', image: '🍦'),
    MenuItem(name: 'Pizza Margherita', price: 250, category: 'Italian', image: '🍕'),
    MenuItem(name: 'Burger Deluxe', price: 180, category: 'Fast Food', image: '🍔'),
  ];

  final Map<MenuItem, int> order = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void addToOrder(MenuItem item) {
    HapticFeedback.lightImpact();
    setState(() {
      order[item] = (order[item] ?? 0) + 1;
    });
    _animationController.forward().then((_) => _animationController.reverse());
  }

  void removeFromOrder(MenuItem item) {
    HapticFeedback.lightImpact();
    setState(() {
      if (order[item] != null && order[item]! > 0) {
        order[item] = order[item]! - 1;
        if (order[item]! <= 0) {
          order.remove(item);
        }
      }
    });
  }

  int getTotalPrice() {
    return order.entries
        .map((entry) => entry.key.price * entry.value)
        .fold(0, (a, b) => a + b);
  }

  List<String> get categories {
    return menuItems.map((item) => item.category).toSet().toList();
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

  void _showRecentOrders(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.history, color: Colors.indigo, size: 24),
              SizedBox(width: 8),
              Text('Recent Orders', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: const Text('No recent orders available.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
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
            icon: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.restaurant, size: isTablet ? 22 : 20),
                if (order.isNotEmpty)
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
                        '${order.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Current Order',
          ),
        ],
        selectedLabelStyle: TextStyle(fontSize: isTablet ? 13 : 11, fontWeight: FontWeight.w600),
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
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
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
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTableSelector(isTablet),
        SizedBox(height: isTablet ? 16 : 12),
        Row(
          children: [
            Icon(Icons.restaurant_menu, color: Colors.indigo, size: isTablet ? 22 : 18),
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
              childAspectRatio: isTablet ? 2.7 : 3.7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return _buildMenuItemCard(item, isTablet);
            },
          ),
        ),
      ],
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
          onTap: () => addToOrder(item),
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
                  child: Column(
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
                ),
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.2).animate(_animationController),
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
                    Icon(Icons.restaurant, color: Colors.indigo, size: isTablet ? 22 : 18),
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
                    if (order.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${order.length} items',
                          style: TextStyle(
                            color: Colors.indigo,
                            fontSize: isTablet ? 11 : 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: isTablet ? 12 : 10),
                Expanded(
                  child: order.isEmpty
                      ? Center(
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
                        )
                      : ListView.separated(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: order.entries.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = order.entries.elementAt(index);
                            return _buildOrderItem(entry, isTablet);
                          },
                        ),
                ),
                if (order.isNotEmpty) ...[
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
                        '₹${getTotalPrice()}',
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
                      icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(MapEntry<MenuItem, int> entry, bool isTablet) {
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
                entry.key.image,
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
                  entry.key.name,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${entry.key.price} × ${entry.value}',
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
                onTap: () => removeFromOrder(entry.key),
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
                onTap: () => addToOrder(entry.key),
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

  Widget _buildTableSelector(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 10),
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
          Icon(Icons.table_restaurant, color: Colors.indigo, size: isTablet ? 18 : 16),
          SizedBox(width: isTablet ? 10 : 6),
          Text(
            'Select Table:',
            style: TextStyle(
              fontSize: isTablet ? 15 : 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedTable,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.indigo, size: 20),
                items: tables.map((table) {
                  return DropdownMenuItem(
                    value: table,
                    child: Text(
                      table,
                      style: TextStyle(
                        fontSize: isTablet ? 13 : 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.indigo,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedTable = value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _placeOrder(BuildContext context) {
    if (order.isEmpty) return;

    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text('Order Confirmation', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Text('Order placed successfully for $selectedTable!\nTotal: ₹${getTotalPrice()}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close bottom sheet
                setState(() => order.clear());
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class MenuItem {
  final String name;
  final int price;
  final String category;
  final String image;

  MenuItem({
    required this.name,
    required this.price,
    required this.category,
    required this.image,
  });

  @override
  bool operator ==(Object other) => other is MenuItem && name == other.name;

  @override
  int get hashCode => name.hashCode;
}