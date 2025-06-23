import 'package:flutter/material.dart';
import 'package:frontend/Ui/kitchen_screen.dart';
import 'package:frontend/Ui/tables_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<_DashboardItem> items = [
    _DashboardItem("Kitchen", Icons.kitchen),
    _DashboardItem("Tables", Icons.dining),
    _DashboardItem("Checkout", Icons.payments),
    _DashboardItem("Rooms", Icons.meeting_room),
    _DashboardItem("Bookings", Icons.book_online),
    _DashboardItem("Customers", Icons.people),
    _DashboardItem("Staff", Icons.person_pin),
    _DashboardItem("Payments", Icons.payment),
    _DashboardItem("Reports", Icons.insert_chart),
    _DashboardItem("Settings", Icons.settings),
    _DashboardItem("Logout", Icons.logout),
  ];

  @override
  Widget build(BuildContext context) {
    final isTabletOrWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Management Dashboard',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTabletOrWeb ? 4 : 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildDashboardCard(item, context);
          },
        ),
      ),
    );
  }

  Widget _buildDashboardCard(_DashboardItem item, BuildContext context) {
    return InkWell(
      onTap: () {
        if(item.title == "Tables"){
          Navigator.push(context, MaterialPageRoute(builder: (context)=>const TableDashboardScreen()));
        }
        else if(item.title == "Kitchen"){
 Navigator.push(context, MaterialPageRoute(builder: (context)=>const KitchenDashboardScreen()));
        }
        // Handle navigation or action
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.title} clicked')),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: Colors.indigo[50],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 40, color: Colors.indigo),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;

  _DashboardItem(this.title, this.icon);
}
