import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/Ui/rooms_screen.dart';
import 'package:frontend/repositories/user_repository.dart';
import 'package:frontend/ui/authentication.dart';
import 'package:frontend/ui/checkout_screen.dart';
import 'package:frontend/ui/customers_screen.dart';
import 'package:frontend/ui/kitchen_screen.dart';
import 'package:frontend/ui/staff_screen.dart';
import 'package:frontend/ui/tables_screen.dart';
import 'package:frontend/widgets/internet_check.dart';
import 'settings.dart';
import 'utilities_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
 
   late List<_DashboardItem> items ;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    final userRole = UserRepository.getUserData()?.role;
    items =  [
   if (userRole == "Chef" || 
      userRole == "Admin")
    _DashboardItem(
      "Kitchen", 
      Icons.restaurant_menu, 
      Colors.orange,
      "Manage orders & menu"
    ),
    if (userRole == "Waiter" || 
      userRole == "Admin")
    _DashboardItem(
        "Tables", Icons.table_restaurant, Colors.blue, "Table reservations"),
        if (
      userRole == "Admin")
    _DashboardItem(
        "Checkout", Icons.point_of_sale, Colors.green, "Process payments"),
        if (
      userRole == "Admin")
    _DashboardItem("Rooms", Icons.hotel, Colors.purple, "Room management"),
    if (
      userRole == "Admin")
    _DashboardItem(
        "Bookings", Icons.event_available, Colors.teal, "View reservations"),
        if (
      userRole == "Admin")
    _DashboardItem(
        "Customers", Icons.people_outline, Colors.indigo, "Customer database"),
        if (
      userRole == "Admin")
    _DashboardItem("Staff", Icons.badge, Colors.brown, "Staff management"),
    if (
      userRole == "Admin")
    _DashboardItem("Payments", Icons.account_balance_wallet, Colors.red,
        "Financial records"),
        if (
      userRole == "Admin")
    _DashboardItem(
        "Reports", Icons.analytics, Colors.deepPurple, "Analytics & insights"),
        if (
      userRole == "Admin")
    _DashboardItem("Utilities", Icons.build, Colors.grey, "System utilities"),
    if (
      userRole == "Admin")
    _DashboardItem(
      
        "Settings", Icons.settings, Colors.blueGrey, "App configuration"),
        if (
      userRole == "Admin")
    _DashboardItem("Logout", Icons.exit_to_app, Colors.redAccent, "Sign out"),
  ];

  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTabletOrWeb = screenSize.width > 600;
    final crossAxisCount =
        screenSize.width > 1200 ? 4 : (isTabletOrWeb ? 3 : 2);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: items.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              childAspectRatio: 0.95,
                            ),
                            itemBuilder: (context, index) {
                              final animationDelay = index * 0.1;
                              final animation = Tween<double>(
                                begin: 0.0,
                                end: 1.0,
                              ).animate(CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  animationDelay,
                                  1.0,
                                  curve: Curves.elasticOut,
                                ),
                              ));

                              return AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: animation.value,
                                    child: _buildDashboardCard(
                                        items[index], context, index),
                                  );
                                },
                              );
                            },
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hotel Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.today, color: Colors.white70, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Today\'s Operations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
      _DashboardItem item, BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _handleCardTap(item, context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
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
            onTap: () => _handleCardTap(item, context),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      item.icon,
                      size: 32,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
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

  void _handleCardTap(_DashboardItem item, BuildContext context) {
    HapticFeedback.selectionClick();

    if (item.title == "Tables") {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const InternetCheckWidget(child: TableDashboardScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
              child: child,
            );
          },
        ),
      );
    } else if (item.title == "Kitchen") {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const InternetCheckWidget(child: KitchenDashboardScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
              child: child,
            );
          },
        ),
      );
    } else if (item.title == "Utilities") {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const InternetCheckWidget(child: UtilityScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
              child: child,
            );
          },
        ),
      );
    } else if (item.title == "Customers") {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const InternetCheckWidget(child: CustomersScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
              child: child,
            );
          },
        ),
      );
    } else if (item.title == "Checkout") {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const InternetCheckWidget(child: CheckoutScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
              child: child,
            );
          },
        ),
      );
    } else if (item.title == "Rooms") {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const InternetCheckWidget(child: RoomsScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
              child: child,
            );
          },
        ),
      );
    } else if (item.title == "Logout") {
      _showLogoutDialog(context);
    } else if (item.title == "Settings") {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const InternetCheckWidget(child: Settings()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
              child: child,
            );
          },
        ),
      );
    } else if(item.title == "Staff"){
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const InternetCheckWidget(child: StaffScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
              child: child,
            );
          },
        ),
      );
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(item.icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${item.title} feature coming soon!',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: item.color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> const AuthScreen()));
                UserRepository.logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final String subtitle;

  _DashboardItem(this.title, this.icon, this.color, this.subtitle);
}
