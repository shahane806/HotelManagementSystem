import 'package:flutter/material.dart';

import '../models/aminity_model.dart';
import '../models/menu_model.dart';
import '../models/room_model.dart';
import '../models/table_model.dart';

class UtilityScreen extends StatefulWidget {
  const UtilityScreen({super.key});
  @override
  State<UtilityScreen> createState() => _UtilityScreenState();
}

class _UtilityScreenState extends State<UtilityScreen> {
  final List<TableModel> tables = [];
  final List<MenuModel> menus = [];
  final List<RoomModel> rooms = [];
  final List<AmenityModel> amenities = [];

  Future<void> _addTable() async {
    final nameController = TextEditingController();
    final countController = TextEditingController();
    final result = await showDialog<TableModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildModernDialog(
        title: "Add New Table",
        icon: Icons.table_restaurant,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: nameController,
              label: "Table Name",
              hint: "e.g., VIP Table 1",
              icon: Icons.table_restaurant_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: countController,
              label: "Seating Capacity",
              hint: "e.g., 4",
              icon: Icons.people_outline,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        onConfirm: () {
          final name = nameController.text.trim();
          final count = int.tryParse(countController.text.trim()) ?? 0;
          if (name.isNotEmpty && count > 0) {
            Navigator.pop(context, TableModel(name: name, count: count));
          } else {
            _showErrorSnackBar("Please fill all fields correctly");
          }
        },
      ),
    );
    if (result != null) {
      setState(() => tables.add(result));
      _showSuccessSnackBar("Table added successfully!");
    }
  }

  Future<void> _addMenu() async {
    final menuController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildModernDialog(
        title: "Create New Menu",
        icon: Icons.restaurant_menu,
        content: _buildTextField(
          controller: menuController,
          label: "Menu Name",
          hint: "e.g., Breakfast Menu",
          icon: Icons.restaurant_menu_outlined,
        ),
        onConfirm: () {
          final name = menuController.text.trim();
          if (name.isNotEmpty) {
            Navigator.pop(context, name);
          } else {
            _showErrorSnackBar("Please enter a menu name");
          }
        },
      ),
    );
    if (result != null) {
      setState(() => menus.add(MenuModel(name: result, items: [])));
      _showSuccessSnackBar("Menu created successfully!");
    }
  }

  Future<void> _addMenuItem(int menuIndex) async {
    final itemController = TextEditingController();
    final priceController = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildModernDialog(
        title: "Add Item to ${menus[menuIndex].name}",
        icon: Icons.fastfood,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: itemController,
              label: "Item Name",
              hint: "e.g., Chicken Biryani",
              icon: Icons.fastfood_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: priceController,
              label: "Price (₹)",
              hint: "e.g., 250",
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        onConfirm: () {
          final item = itemController.text.trim();
          final price = priceController.text.trim();
          if (item.isNotEmpty && price.isNotEmpty) {
            Navigator.pop(context, {"item": item, "price": price});
          } else {
            _showErrorSnackBar("Please fill all fields");
          }
        },
      ),
    );
    if (result != null) {
      setState(() {
        menus[menuIndex].items.add("${result['item']} - ₹${result['price']}");
      });
      _showSuccessSnackBar("Menu item added successfully!");
    }
  }

  Future<void> _addRoom() async {
    final roomController = TextEditingController();
    final priceController = TextEditingController();
    bool isAC = false;

    final result = await showDialog<RoomModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => _buildModernDialog(
            title: "Add New Room",
            icon: Icons.hotel,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: roomController,
                  label: "Room Name/Number",
                  hint: "e.g., Deluxe Room 101",
                  icon: Icons.hotel_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: priceController,
                  label: "Price per Night (₹)",
                  hint: "e.g., 2500",
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.ac_unit, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Air Conditioned Room",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Switch(
                        value: isAC,
                        onChanged: (val) {
                          setStateDialog(() => isAC = val);
                        },
                        activeColor: Colors.blue[600],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            onConfirm: () {
              final name = roomController.text.trim();
              final price = priceController.text.trim();
              if (name.isNotEmpty && price.isNotEmpty) {
                Navigator.pop(context, RoomModel(name: "$name - ₹$price/night", isAC: isAC));
              } else {
                _showErrorSnackBar("Please fill all fields");
              }
            },
          ),
        );
      },
    );

    if (result != null) {
      setState(() => rooms.add(result));
      _showSuccessSnackBar("Room added successfully!");
    }
  }

  Future<void> _addAmenity() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildModernDialog(
        title: "Add Hotel Amenity",
        icon: Icons.spa,
        content: _buildTextField(
          controller: controller,
          label: "Amenity Name",
          hint: "e.g., Swimming Pool",
          icon: Icons.spa_outlined,
        ),
        onConfirm: () {
          final name = controller.text.trim();
          if (name.isNotEmpty) {
            Navigator.pop(context, name);
          } else {
            _showErrorSnackBar("Please enter an amenity name");
          }
        },
      ),
    );
    if (result != null) {
      setState(() => amenities.add(AmenityModel(name: result)));
      _showSuccessSnackBar("Amenity added successfully!");
    }
  }

  Widget _buildModernDialog({
    required String title,
    required IconData icon,
    required Widget content,
    required VoidCallback onConfirm,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[600]!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 32, color: Colors.blue[600]),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            content,
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Add"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

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
              _buildHeader(context, screenWidth),
              const SizedBox(height: 20),
              Expanded(
                child: _buildContentGrid(context, screenWidth, isTablet, isDesktop),
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
            child: const Icon(Icons.settings, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              "Hotel Utilities",
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
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, double screenWidth) {
    final totalItems = tables.length + menus.length + rooms.length + amenities.length;
    
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
                  "Management Center",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth > 600 ? 18 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$totalItems items configured",
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
              Icons.dashboard_customize,
              color: Colors.white,
              size: screenWidth > 600 ? 28 : 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentGrid(BuildContext context, double screenWidth, bool isTablet, bool isDesktop) {
    if (isDesktop) {
      return GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          _buildModernSection("Tables", Icons.table_restaurant, Colors.orange, tables.map((t) => "${t.name} (${t.count} seats)").toList(), _addTable),
          _buildModernSection("Rooms", Icons.hotel, Colors.purple, rooms.map((r) => "${r.name} - ${r.isAC ? "AC" : "Non-AC"}").toList(), _addRoom),
          _buildMenuSection(),
          _buildModernSection("Amenities", Icons.spa, Colors.green, amenities.map((a) => a.name).toList(), _addAmenity),
        ],
      );
    } else {
      return ListView(
        children: [
          _buildModernSection("Tables", Icons.table_restaurant, Colors.orange, tables.map((t) => "${t.name} (${t.count} seats)").toList(), _addTable),
          const SizedBox(height: 16),
          _buildMenuSection(),
          const SizedBox(height: 16),
          _buildModernSection("Rooms", Icons.hotel, Colors.purple, rooms.map((r) => "${r.name} - ${r.isAC ? "AC" : "Non-AC"}").toList(), _addRoom),
          const SizedBox(height: 16),
          _buildModernSection("Amenities", Icons.spa, Colors.green, amenities.map((a) => a.name).toList(), _addAmenity),
        ],
      );
    }
  }

  Widget _buildModernSection(String title, IconData icon, Color color, List<String> items, VoidCallback onAdd) {
    return Card(
      elevation: 4,
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            "${items.length} items",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          childrenPadding: const EdgeInsets.all(16),
          children: [
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, color: Colors.grey[400], size: 32),
                    const SizedBox(width: 12),
                    Text(
                      "No ${title.toLowerCase()} added yet",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              ...items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text("Add ${title.substring(0, title.length - 1)}"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Card(
      elevation: 4,
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant_menu, color: Colors.red, size: 24),
          ),
          title: const Text(
            "Menus",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            "${menus.length} menus",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          childrenPadding: const EdgeInsets.all(16),
          children: [
            if (menus.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu_outlined, color: Colors.grey[400], size: 32),
                    const SizedBox(width: 12),
                    Text(
                      "No menus created yet",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              ...menus.asMap().entries.map((entry) {
                final index = entry.key;
                final menu = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fastfood, color: Colors.red, size: 20),
                      ),
                      title: Text(
                        menu.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text("${menu.items.length} items"),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (menu.items.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "No items in this menu yet",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                ...menu.items.map((item) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _addMenuItem(index),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text("Add Menu Item"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addMenu,
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Menu"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}