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
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  void removeFromOrder(MenuItem item) {
    HapticFeedback.lightImpact();
    setState(() {
      if (order[item] != null) {
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 900;
    final isTablet = screenSize.width > 600;

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
              _buildAppBar(context, isTablet),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 24 : 16),
                      child: isWideScreen
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _buildMenuSection(context)),
                                const SizedBox(width: 24),
                                Expanded(flex: 2, child: _buildOrderSection(context)),
                              ],
                            )
                          : Column(
                              children: [
                                Expanded(child: _buildMenuSection(context)),
                                Container(
                                  height: screenSize.height * 0.4,
                                  child: _buildOrderSection(context),
                                ),
                              ],
                            ),
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
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Table Orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage table orders and menu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTableSelector(isTablet),
        SizedBox(height: isTablet ? 20 : 16),
        
        Row(
          children: [
            Icon(Icons.restaurant_menu, color: Colors.indigo, size: isTablet ? 24 : 20),
            const SizedBox(width: 8),
            Text(
              'Menu Items',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        
        SizedBox(height: isTablet ? 12 : 8),
        
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 2 : 1,
              childAspectRatio: isTablet ? 2.5 : 3.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => addToOrder(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 60 : 50,
                  height: isTablet ? 60 : 50,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      item.image,
                      style: TextStyle(fontSize: isTablet ? 24 : 20),
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.category,
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${item.price}',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                ScaleTransition(
                  scale: _animationController,
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 12 : 8),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: isTablet ? 20 : 16,
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

  Widget _buildOrderSection(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.indigo, size: isTablet ? 24 : 20),
                const SizedBox(width: 8),
                Text(
                  'Current Order',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                if (order.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${order.length} items',
                      style: TextStyle(
                        color: Colors.indigo,
                        fontSize: isTablet ? 12 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: isTablet ? 16 : 12),
            
            Expanded(
              child: order.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: isTablet ? 64 : 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items added',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start adding items from menu',
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
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
              const Divider(thickness: 2),
              SizedBox(height: isTablet ? 12 : 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount:',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  Text(
                    '₹${getTotalPrice()}',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isTablet ? 16 : 12),
              
              SizedBox(
                width: double.infinity,
                height: isTablet ? 50 : 45,
                child: ElevatedButton.icon(
                  onPressed: () => _placeOrder(),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: Text(
                    'Place Order',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(MapEntry<MenuItem, int> entry, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 8),
      child: Row(
        children: [
          Container(
            width: isTablet ? 40 : 32,
            height: isTablet ? 40 : 32,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                entry.key.image,
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 12 : 8),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key.name,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${entry.key.price} × ${entry.value}',
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
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
                  padding: EdgeInsets.all(isTablet ? 8 : 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: isTablet ? 16 : 14,
                    color: Colors.red,
                  ),
                ),
              ),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12),
                child: Text(
                  '${entry.value}',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ),
              
              GestureDetector(
                onTap: () => addToOrder(entry.key),
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 8 : 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.add,
                    size: isTablet ? 16 : 14,
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
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.table_restaurant, color: Colors.indigo, size: isTablet ? 20 : 18),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedTable,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.indigo),
                items: tables.map((table) {
                  return DropdownMenuItem(
                    value: table,
                    child: Text(
                      table,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
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

  void _placeOrder() {
    if (order.isEmpty) return;
    
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 2),
              const Text('Order Confirmation',style: TextStyle(
                fontSize: 20,
              ),),
            ],
          ),
          content: Text('Order placed successfully for $selectedTable!\nTotal: ₹${getTotalPrice()}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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