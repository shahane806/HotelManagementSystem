import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../bloc/AmenitiesUtility/bloc.dart';
import '../bloc/AmenitiesUtility/event.dart';
import '../bloc/AmenitiesUtility/state.dart';
import '../bloc/MenuUtility/bloc.dart';
import '../bloc/MenuUtility/event.dart';
import '../bloc/MenuUtility/state.dart';
import '../bloc/RoomUtility/bloc.dart';
import '../bloc/RoomUtility/event.dart';
import '../bloc/RoomUtility/state.dart';
import '../bloc/TableUtility/bloc.dart';
import '../bloc/TableUtility/event.dart';
import '../bloc/TableUtility/state.dart';
import '../models/table_model.dart';

class UtilityScreen extends StatefulWidget {
  const UtilityScreen({super.key});
  @override
  State<UtilityScreen> createState() => _UtilityScreenState();
}

class _UtilityScreenState extends State<UtilityScreen> {
  String? selectedUtilityName;

  Future<void> _addTableItem() async {
    final nameController = TextEditingController();
    final countController = TextEditingController();
    String? selectedUtilityId;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocBuilder<TablesBloc, TablesState>(
        builder: (context, state) {
          List<TableModel> utilities = [];
          if (state is TablesLoaded) {
            utilities = state.tables;
          }
          return _buildModernDialog(
            title: "Add Table",
            icon: Icons.table_restaurant,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (utilities.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: const Text(
                      "No utilities available. Please create a utility first.",
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Select Utility",
                      prefixIcon: Icon(Icons.table_restaurant_outlined, color: Colors.blue[600]),
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
                    value: selectedUtilityId,
                    items: utilities
                        .map((utility) => DropdownMenuItem(
                              value: utility.id,
                              child: Text(utility.utilityName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      selectedUtilityId = value;
                      selectedUtilityName = utilities.firstWhere((u) => u.id == value).utilityName;
                    },
                    hint: const Text("Choose a utility"),
                  ),
                const SizedBox(height: 16),
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
              if (selectedUtilityId != null && name.isNotEmpty && count > 0) {
                Navigator.pop(context, {
                  "utilityId": selectedUtilityId,
                  "name": name,
                  "count": count,
                });
              } else {
                _showErrorSnackBar("Please select a utility and fill all fields correctly");
              }
            },
          );
        },
      ),
    );

    if (result != null) {
       if(mounted){
        context.read<TablesBloc>().add(AddTableItem(
            result['utilityId'],
            result['name'],
            result['count'],
          ));
       }
      _showSuccessSnackBar("Table item added successfully!");
    }
  }

  Future<void> _deleteTableItem(String utilityId, String itemName) async {
    if (utilityId.isEmpty || itemName.isEmpty) {
      _showErrorSnackBar("Invalid utility ID or item name");
      return;
    }
    context.read<TablesBloc>().add(DeleteTableItem(utilityId, itemName));
    _showSuccessSnackBar("Table item deleted successfully!");
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
          if (name.isNotEmpty && name.toLowerCase() != 'me') {
            Navigator.pop(context, name);
          } else {
            _showErrorSnackBar("Please enter a valid menu name (not 'me')");
          }
        },
      ),
    );
    if (result != null) {
       if(mounted){
        context.read<MenusBloc>().add(AddMenus(result));
       }
      _showSuccessSnackBar("Menu created successfully!");
    }
  }

  Future<void> _addMenuItem(String menuName) async {
    if (menuName.isEmpty) {
      _showErrorSnackBar("Invalid menu name: $menuName");
      return;
    }
    final itemController = TextEditingController();
    final priceController = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildModernDialog(
        title: "Add Item to $menuName",
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
       if(mounted){
        context.read<MenusBloc>().add(AddMenuItem(menuName, result['item'], result['price']));
       }
      _showSuccessSnackBar("Menu item added successfully!");
    }
  }

  Future<void> _deleteMenu(String menuName) async {
    if (menuName.isEmpty) {
      _showErrorSnackBar("Invalid menu name: $menuName");
      return;
    }
    context.read<MenusBloc>().add(DeleteMenus(menuName));
    _showSuccessSnackBar("Menu deleted successfully!");
  }

  Future<void> _deleteMenuItem(String menuName, String itemName) async {
    if (menuName.isEmpty || itemName.isEmpty) {
      _showErrorSnackBar("Invalid menu or item name");
      return;
    }
    context.read<MenusBloc>().add(DeleteMenuItem(menuName, itemName));
    _showSuccessSnackBar("Menu item deleted successfully!");
  }

  Future<void> _addRoom() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    bool isAC = false;

    final result = await showDialog<Map<String, dynamic>>(
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
                  controller: nameController,
                  label: "Room Number",
                  hint: "e.g., 101",
                  icon: Icons.hotel_outlined,
                  keyboardType: TextInputType.number,
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
              final name = int.tryParse(nameController.text.trim());
              final price = priceController.text.trim();
              if (name != null && name > 0 && price.isNotEmpty) {
                Navigator.pop(context, {
                  'name': name,
                  'price': price,
                  'isAC': isAC,
                });
              } else {
                _showErrorSnackBar("Please enter a valid room number and price");
              }
            },
          ),
        );
      },
    );

    if (result != null) {
       if(mounted){
        context.read<RoomsBloc>().add(AddRoom(result['name'], result['price'], result['isAC']));
       }
      _showSuccessSnackBar("Room added successfully!");
    }
  }

  Future<void> _deleteRoom(int name) async {
    if (name <= 0) {
      _showErrorSnackBar("Invalid room number");
      return;
    }
    context.read<RoomsBloc>().add(DeleteRoom(name));
    _showSuccessSnackBar("Room deleted successfully!");
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
       if(mounted){
        context.read<AmenitiesBloc>().add(AddAmenities(result));
       }
      _showSuccessSnackBar("Amenity added successfully!");
    }
  }

  Future<void> _deleteAmenity(String amenityName) async {
    context.read<AmenitiesBloc>().add(DeleteAmenities(amenityName));
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

  Widget _buildShimmerSection({required double screenWidth}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        elevation: 4,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: screenWidth * 0.25,
                        height: 18,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: screenWidth * 0.15,
                        height: 12,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 14,
                        color: Colors.grey[300],
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    
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
          onPressed: () {
            context.read<AmenitiesBloc>().add(FetchAmenities());
            context.read<MenusBloc>().add(FetchMenus());
            context.read<TablesBloc>().add(FetchTables());
            context.read<RoomsBloc>().add(FetchRooms());
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, double screenWidth) {
    return BlocBuilder<AmenitiesBloc, AmenitiesState>(
      builder: (context, amenityState) {
        int amenitiesCount = 0;
        if (amenityState is AmenitiesLoaded) {
          amenitiesCount = amenityState.amenities.length;
        }
        return BlocBuilder<MenusBloc, MenusState>(
          builder: (context, menuState) {
            int menusCount = 0;
            if (menuState is MenusLoaded) {
              menusCount = menuState.menus.length;
            }
            return BlocBuilder<TablesBloc, TablesState>(
              builder: (context, tableState) {
                int tablesCount = 0;
                if (tableState is TablesLoaded) {
                  tablesCount = tableState.tables.fold(
                      0, (sum, table) => sum + table.utilityItems.length);
                }
                return BlocBuilder<RoomsBloc, RoomState>(
                  builder: (context, roomState) {
                    int roomsCount = 0;
                    if (roomState is RoomLoaded) {
                      roomsCount = roomState.rooms.length;
                    }
                    final totalItems = tablesCount + roomsCount + amenitiesCount + menusCount;

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
                  },
                );
              },
            );
          },
        );
      },
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
          _buildTableSection(screenWidth),
          BlocBuilder<RoomsBloc, RoomState>(
            builder: (context, state) {
              if (state is RoomLoading) {
                return _buildShimmerSection(screenWidth: screenWidth);
              } else if (state is RoomLoaded) {
                print('Rooms loaded: ${state.rooms.map((r) => r.name).toList()}');
                return _buildModernSection(
                  "Rooms",
                  Icons.hotel,
                  Colors.purple,
                  state.rooms.map((r) => "Room ${r.name} - ₹${r.price}/night - ${r.isAC ? 'AC' : 'Non-AC'}").toList(),
                  _addRoom,
                  onDelete: (display) {
                    final name = int.parse(display.split(' ')[1]); // Extract name from "Room X - ₹Y/night - Z"
                    _deleteRoom(name);
                  },
                  screenWidth: screenWidth,
                );
              } else if (state is RoomError) {
                print('Rooms error: ${state.message}');
                return _buildModernSection(
                  "Rooms",
                  Icons.hotel,
                  Colors.purple,
                  [],
                  _addRoom,
                  onDelete: (_) {},
                  errorMessage: state.message,
                  screenWidth: screenWidth,
                );
              }
              print('No rooms loaded');
              return _buildModernSection(
                "Rooms",
                Icons.hotel,
                Colors.purple,
                [],
                _addRoom,
                onDelete: (_) {},
                screenWidth: screenWidth,
              );
            },
          ),
          _buildMenuSection(screenWidth),
          BlocBuilder<AmenitiesBloc, AmenitiesState>(
            builder: (context, state) {
              if (state is AmenitiesLoading) {
                return _buildShimmerSection(screenWidth: screenWidth);
              } else if (state is AmenitiesLoaded) {
                final amenityNames = state.amenities
                    .expand((a) => a.name.isNotEmpty == true ? [a.name] : ['Unnamed Amenity'])
                    .toList();
                print('Amenities loaded: $amenityNames');
                return _buildModernSection(
                  "Amenities",
                  Icons.spa,
                  Colors.green,
                  amenityNames,
                  _addAmenity,
                  onDelete: _deleteAmenity,
                  screenWidth: screenWidth,
                );
              } else if (state is AmenitiesError) {
                print('Amenities error: ${state.message}');
                return Center(child: Text(state.message));
              }
              print('No amenities loaded');
              return _buildModernSection(
                "Amenities",
                Icons.spa,
                Colors.green,
                [],
                _addAmenity,
                onDelete: _deleteAmenity,
                screenWidth: screenWidth,
              );
            },
          ),
        ],
      );
    } else {
      return ListView(
        children: [
          _buildTableSection(screenWidth),
          const SizedBox(height: 16),
          _buildMenuSection(screenWidth),
          const SizedBox(height: 16),
          BlocBuilder<RoomsBloc, RoomState>(
            builder: (context, state) {
              if (state is RoomLoading) {
                return _buildShimmerSection(screenWidth: screenWidth);
              } else if (state is RoomLoaded) {
                print('Rooms loaded: ${state.rooms.map((r) => r.name).toList()}');
                return _buildModernSection(
                  "Rooms",
                  Icons.hotel,
                  Colors.purple,
                  state.rooms.map((r) => "Room ${r.name} - ₹${r.price}/night - ${r.isAC ? 'AC' : 'Non-AC'}").toList(),
                  _addRoom,
                  onDelete: (display) {
                    final name = int.parse(display.split(' ')[1]); // Extract name from "Room X - ₹Y/night - Z"
                    _deleteRoom(name);
                  },
                  screenWidth: screenWidth,
                );
              } else if (state is RoomError) {
                print('Rooms error: ${state.message}');
                return _buildModernSection(
                  "Rooms",
                  Icons.hotel,
                  Colors.purple,
                  [],
                  _addRoom,
                  onDelete: (_) {},
                  errorMessage: state.message,
                  screenWidth: screenWidth,
                );
              }
              print('No rooms loaded');
              return _buildModernSection(
                "Rooms",
                Icons.hotel,
                Colors.purple,
                [],
                _addRoom,
                onDelete: (_) {},
                screenWidth: screenWidth,
              );
            },
          ),
          const SizedBox(height: 16),
          BlocBuilder<AmenitiesBloc, AmenitiesState>(
            builder: (context, state) {
              if (state is AmenitiesLoading) {
                return _buildShimmerSection(screenWidth: screenWidth);
              } else if (state is AmenitiesLoaded) {
                final amenityNames = state.amenities
                    .expand((a) => a.name.isNotEmpty == true ? [a.name] : ['Unnamed Amenity'])
                    .toList();
                print('Amenities loaded: $amenityNames');
                return _buildModernSection(
                  "Amenities",
                  Icons.spa,
                  Colors.green,
                  amenityNames,
                  _addAmenity,
                  onDelete: _deleteAmenity,
                  screenWidth: screenWidth,
                );
              } else if (state is AmenitiesError) {
                print('Amenities error: ${state.message}');
                return Center(child: Text(state.message));
              }
              if (kDebugMode) {
                print('No amenities loaded');
              }
              return _buildModernSection(
                "Amenities",
                Icons.spa,
                Colors.green,
                [],
                _addAmenity,
                onDelete: _deleteAmenity,
                screenWidth: screenWidth,
              );
            },
          ),
        ],
      );
    }
  }

  Widget _buildTableSection(double screenWidth) {
    return BlocBuilder<TablesBloc, TablesState>(
      builder: (context, state) {
        if (state is TablesLoading) {
          return _buildShimmerSection(screenWidth: screenWidth);
        } else if (state is TablesLoaded) {
          print('Table utilities loaded: ${state.tables.map((t) => t.utilityName).toList()}');
          final tableItems = state.tables
              .expand((table) => table.utilityItems
                  .map((item) => {
                        'display': "${item.name} (${item.count} seats)",
                        'utilityId': table.id,
                        'itemName': item.name,
                      }))
              .toList();
          return _buildModernSection(
            "Tables",
            Icons.table_restaurant,
            Colors.orange,
            tableItems.map((item) => item['display'] as String).toList(),
            _addTableItem,
            onDelete: (display) {
              final item = tableItems.firstWhere((i) => i['display'] == display);
              print('Deleting table item: ${item['itemName']} from utility: ${item['utilityId']}');
              _deleteTableItem(item['utilityId'] as String, item['itemName'] as String);
            },
            screenWidth: screenWidth,
          );
        } else if (state is TablesError) {
          print('Tables error: ${state.message}');
          return _buildModernSection(
            "Tables",
            Icons.table_restaurant,
            Colors.orange,
            [],
            _addTableItem,
            errorMessage: state.message,
            screenWidth: screenWidth,
          );
        }
        print('No table utilities loaded');
        return _buildModernSection(
          "Tables",
          Icons.table_restaurant,
          Colors.orange,
          [],
          _addTableItem,
          screenWidth: screenWidth,
        );
      },
    );
  }

  Widget _buildModernSection(
    String title,
    IconData icon,
    Color color,
    List<String> items,
    VoidCallback onAdd, {
    Function(String)? onDelete,
    String? errorMessage,
    required double screenWidth,
  }) {
    print('Building $title section with items: $items');
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
            errorMessage != null ? "Error loading $title" : "${items.length} items",
            style: TextStyle(color: errorMessage != null ? Colors.red[600] : Colors.grey[600], fontSize: 12),
          ),
          childrenPadding: const EdgeInsets.all(16),
          children: [
            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[400], size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red[600], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else if (items.isEmpty)
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
              ...items.map((item) {
                print('Rendering item: $item');
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      if (onDelete != null)
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                          onPressed: () {
                            print('Deleting item: $item');
                            onDelete(item);
                          },
                        ),
                    ],
                  ),
                );
              }).toList(),
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

  Widget _buildMenuSection(double screenWidth) {
    return BlocBuilder<MenusBloc, MenusState>(
      builder: (context, state) {
        if (state is MenusLoading) {
          return _buildShimmerSection(screenWidth: screenWidth);
        } else if (state is MenusLoaded) {
          print('Menus loaded: ${state.menus.map((m) => m.name).toList()}');
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
                  "${state.menus.length} menus",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  if (state.menus.isEmpty)
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
                    ...state.menus.map((menu) {
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
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                              onPressed: () {
                                print('Deleting menu: ${menu.name}');
                                _deleteMenu(menu.name);
                              },
                            ),
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
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.red.withOpacity(0.2)),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 4,
                                                  height: 4,
                                                  margin: const EdgeInsets.only(top: 4),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    "${item.menuitemname} - ₹${item.price}",
                                                    style: const TextStyle(fontSize: 13),
                                                    overflow: TextOverflow.visible,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                                                  onPressed: () {
                                                    print('Deleting menu item: ${item.menuitemname} from menu: ${menu.name}');
                                                    _deleteMenuItem(menu.name, item.menuitemname);
                                                  },
                                                ),
                                              ],
                                            ),
                                          )),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _addMenuItem(menu.name),
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
                    }).toList(),
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
        } else if (state is MenusError) {
          print('Menus error: ${state.message}');
          String displayMessage = state.message.contains('404')
              ? 'Menu not found. Please check the menu name or server configuration.'
              : state.message;
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
                  "Error loading menus",
                  style: TextStyle(color: Colors.red[600], fontSize: 12),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[400], size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            displayMessage,
                            style: TextStyle(color: Colors.red[600], fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
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
        print('No menus loaded');
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
                "0 menus",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              childrenPadding: const EdgeInsets.all(16),
              children: [
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
                ),
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
      },
    );
  }
}