import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/room_card.dart';
import '../bloc/RoomsBloc/bloc.dart';
import '../bloc/RoomsBloc/event.dart';
import '../bloc/RoomsBloc/state.dart';
import 'room_detail_screen.dart';
import 'room_form_screen.dart';

class RoomsScreen extends StatefulWidget {
  final bool isAdminView;

  const RoomsScreen({super.key, this.isAdminView = true});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  String selectedFilter = 'All';
  String sortBy = 'Price: Low to High';
  @override
  void initState(){
    super.initState();
    context.read<RoomBloc>().add(LoadRooms());
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
  elevation: 0,
  backgroundColor: Colors.transparent,
  foregroundColor: Colors.black87,
  title: SizedBox(
    height: 56, // IMPORTANT
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.isAdminView ? 'Manage Rooms' : 'Discover Rooms',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Text(
          widget.isAdminView
              ? 'Add, edit & manage hotel rooms'
              : 'Find your perfect stay',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
        ),
        actions: [
          if (!widget.isAdminView)
            IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () {},
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      floatingActionButton: widget.isAdminView
          ? FloatingActionButton.extended(
              backgroundColor: Colors.indigo[700],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Room',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoomFormScreen()),
                );
                if (result == true) {
                  context.read<RoomBloc>().add(LoadRooms());
                }
              },
            )
          : null,
      body: Column(
        children: [
          // Filter chips
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Available'),
                  _buildFilterChip('Standard'),
                  _buildFilterChip('Deluxe'),
                  _buildFilterChip('Suite'),
                ],
              ),
            ),
          ),

          // Rooms list / grid
          Expanded(
            child: BlocBuilder<RoomBloc, RoomState>(
              builder: (context, state) {
                print("Om Shahane : ${state}");
                if (state is RoomLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
              
                if (state is RoomLoaded) {
                  if (state.rooms.isEmpty) {
                    return _buildEmptyState();
                  }

                  final filteredRooms = _filterRooms(state.rooms);
                  final sortedRooms = _sortRooms(filteredRooms);

                  // User view: Beautiful Grid
                  if (!widget.isAdminView) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: sortedRooms.length,
                      itemBuilder: (context, index) {
                        final room = sortedRooms[index];
                        return RoomCard(
                          room: room,
                          isAdminView: false,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RoomDetailScreen(room: room),
                              ),
                            );
                            if (result == true) {
                              context.read<RoomBloc>().add(LoadRooms());
                            }
                          },
                        );
                      },
                    );
                  }

                  // Admin view: Simple vertical list
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<RoomBloc>().add(LoadRooms());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 16, bottom: 90),
                      itemCount: sortedRooms.length,
                      itemBuilder: (_, index) {
                        final room = sortedRooms[index];
                        return RoomCard(
                          room: room,
                          isAdminView: true,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RoomDetailScreen(room: room),
                              ),
                            );
                            if (result == true) {
                              context.read<RoomBloc>().add(LoadRooms());
                            }
                          },
                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RoomFormScreen(room: room),
                              ),
                            );
                            if (result == true) {
                              context.read<RoomBloc>().add(LoadRooms());
                            }
                          },
                          onDelete: () {
                            context.read<RoomBloc>().add(DeleteRoomEvent(room.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Room deleted successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }

                if (state is RoomError) {
                  return _buildErrorState(state.message);
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedFilter = label;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.indigo[700],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isAdminView ? Icons.hotel_outlined : Icons.search_off,
            size: 120,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            widget.isAdminView ? 'No rooms added yet' : 'No rooms available',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.isAdminView
                ? 'Tap the + button to add your first room'
                : 'Try adjusting your filters or search',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 120, color: Colors.red[300]),
          const SizedBox(height: 24),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.read<RoomBloc>().add(LoadRooms()),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterRooms(List<dynamic> rooms) {
    if (selectedFilter == 'All') return rooms;
    if (selectedFilter == 'Available') {
      return rooms.where((r) => r.status == 'available').toList();
    }
    return rooms.where((r) => r.type == selectedFilter.toLowerCase()).toList();
  }

  List<dynamic> _sortRooms(List<dynamic> rooms) {
    final sorted = List.from(rooms);
    switch (sortBy) {
      case 'Price: Low to High':
        sorted.sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
        break;
      case 'Price: High to Low':
        sorted.sort((a, b) => b.pricePerNight.compareTo(a.pricePerNight));
        break;
      case 'Rating':
        sorted.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
    }
    return sorted;
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sort & Filter',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => sortBy = 'Price: Low to High');
                      setModalState(() => {});
                      Navigator.pop(context);
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Sort By',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildSortOption('Price: Low to High', setModalState),
              _buildSortOption('Price: High to Low', setModalState),
              _buildSortOption('Rating', setModalState),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(String option, StateSetter setModalState) {
    final isSelected = sortBy == option;
    return RadioListTile<String>(
      title: Text(option, style: const TextStyle(fontSize: 16)),
      value: option,
      groupValue: sortBy,
      onChanged: (value) {
        setState(() {
          sortBy = value!;
        });
        setModalState(() {});
      },
      activeColor: Colors.indigo[700],
      selected: isSelected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}