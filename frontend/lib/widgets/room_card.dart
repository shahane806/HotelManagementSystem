import 'package:flutter/material.dart';
import '../../models/hotel_room_model.dart';
import '../ui/room_detail_screen.dart';

class RoomCard extends StatelessWidget {
  final HotelRoomModel room;
  final bool isAdminView;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoomCard({
    super.key,
    required this.room,
    this.isAdminView = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // For admin view: Simple elevated card with actions
    if (isAdminView) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              room.images.isNotEmpty ? room.images[0] : 'https://via.placeholder.com/150',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.hotel)),
            ),
          ),
          title: Text('Room ${room.roomNo} • ${room.type}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('₹${room.pricePerNight.toStringAsFixed(0)} / night'),
              Text('Status: ${room.status.toUpperCase()}', style: TextStyle(color: room.status == 'available' ? Colors.green : Colors.orange)),
              Text('${room.capacity} Guests • Floor ${room.floor}'),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit?.call();
              if (value == 'delete') onDelete?.call();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete), SizedBox(width: 8), Text('Delete')])),
            ],
          ),
          onTap: onTap,
        ),
      );
    }

    // For user view: Stunning Airbnb-style card with overlay
    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RoomDetailScreen(room: room)),
            );
          },
      child: Container(
        height: 300,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main Room Image
              Image.network(
                room.images.isNotEmpty ? room.images[0] : 'https://via.placeholder.com/400x300',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.hotel, size: 80, color: Colors.grey),
                ),
              ),

              // Dark Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.4, 0.7, 1.0],
                  ),
                ),
              ),

              // Content at Bottom
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Room ${room.roomNo} • ${room.capacity} Guests',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${room.pricePerNight.toStringAsFixed(0)} / night',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              room.rating?.toStringAsFixed(1) ?? '4.9',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Favorite Button
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    color: Colors.red[600],
                    size: 24,
                  ),
                ),
              ),

              // Status Badge (if not available)
              if (room.status != 'available')
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[700],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Booked',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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