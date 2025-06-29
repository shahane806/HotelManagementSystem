import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/AmenitiesUtility/bloc.dart';
import '../bloc/AmenitiesUtility/event.dart';
import '../bloc/AmenitiesUtility/state.dart';

class UtilityScreen extends StatefulWidget {
  const UtilityScreen({super.key});

  @override
  State<UtilityScreen> createState() => _UtilityScreenState();
}

class _UtilityScreenState extends State<UtilityScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AmenitiesBloc>().add(FetchAmenities());
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
                child: _buildContentGrid(context),
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
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, double screenWidth) {
    return BlocBuilder<AmenitiesBloc, AmenitiesState>(
      builder: (context, state) {
        int totalItems = 0;
        if (state is AmenitiesLoaded) {
          totalItems = state.amenities.fold<int>(
              0, (sum, model) => sum + model.utilityItems.length);
        }
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
  }

  Widget _buildContentGrid(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: BlocBuilder<AmenitiesBloc, AmenitiesState>(
            builder: (context, state) {
              if (state is AmenitiesLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is AmenitiesError) {
                return Center(child: Text(state.message));
              } else if (state is AmenitiesLoaded) {
                final amenities = state.amenities.expand((e) => e.utilityItems).cast<String>().toList();
                return ListView(
                  children: [
                    _buildModernSection(
                      context,
                      "Amenities",
                      Icons.spa,
                      Colors.green,
                      amenities,
                      () => _addAmenity(context),
                    ),
                  ],
                );
              }
              return const Center(child: Text("No amenities available"));
            },
          ),
        ),
        const SizedBox(height: 16),
      
      ],
    );
  }

  Future<void> _addAmenity(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Add Amenity"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter amenity name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Add"),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      context.read<AmenitiesBloc>().add(AddAmenities(result));
      _showSuccessSnackBar(context, "Amenity added successfully!");
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _deleteAmenity(BuildContext context, String name) {
    context.read<AmenitiesBloc>().add(DeleteAmenities(name));
    _showSuccessSnackBar(context, "Amenity deleted successfully!");
  }

  Widget _buildModernSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<String> items,
    VoidCallback onAdd,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${items.length} items"),
        children: [
          ...items.map((item) => ListTile(
                title: Text(item),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteAmenity(context, item),
                ),
              )),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text("Add ${title.substring(0, title.length - 1)}"),
          ),
        ],
      ),
    );
  }
}
