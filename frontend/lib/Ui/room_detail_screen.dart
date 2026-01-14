import 'package:flutter/material.dart';
import '../../models/hotel_room_model.dart';
import '../app/api_constants.dart';
import 'room_booking_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final HotelRoomModel room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  int currentImageIndex = 0;
  bool isFavorite = false;

  // Mock reviews - replace with real data later
  final List<Map<String, dynamic>> reviews = [
    {
      'name': 'Rajesh Kumar',
      'rating': 5.0,
      'date': '2 days ago',
      'comment':
          'Absolutely amazing room! The view was spectacular and the staff was very helpful. Would definitely recommend.',
      'avatar': 'R',
    },
    {
      'name': 'Priya Sharma',
      'rating': 4.5,
      'date': '1 week ago',
      'comment':
          'Great room with excellent amenities. Only minor issue was the WiFi speed, but overall a wonderful stay.',
      'avatar': 'P',
    },
    {
      'name': 'Amit Patel',
      'rating': 5.0,
      'date': '2 weeks ago',
      'comment':
          'Perfect for a business trip. Clean, comfortable, and well-maintained. The work desk was very convenient.',
      'avatar': 'A',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final avgRating = reviews.isEmpty
        ? widget.room.rating ?? 4.5
        : reviews.map((r) => r['rating'] as double).reduce((a, b) => a + b) / reviews.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                ),
                child: IconButton(
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                  onPressed: () => setState(() => isFavorite = !isFavorite),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                ),
                child: IconButton(icon: const Icon(Icons.share), onPressed: () {}),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: widget.room.images.length,
                    onPageChanged: (i) => setState(() => currentImageIndex = i),
                    itemBuilder: (_, index) => Image.network(
                     "${ApiConstants.url}/${widget.room.images[index]}",
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 80),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  if (widget.room.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.room.images.length,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: currentImageIndex == i ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: currentImageIndex == i ? Colors.white : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.room.status == 'available' ? Colors.green[100] : Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.room.status.toUpperCase(),
                              style: TextStyle(
                                color: widget.room.status == 'available' ? Colors.green[800] : Colors.orange[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              widget.room.type,
                              style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Room ${widget.room.roomNo}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[700], size: 20),
                          const SizedBox(width: 4),
                          Text('${avgRating.toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Text('(${reviews.length} reviews)', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildInfoChip(Icons.people_outline, '${widget.room.capacity} Guests'),
                          const SizedBox(width: 12),
                          _buildInfoChip(Icons.layers_outlined, 'Floor ${widget.room.floor}'),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 8),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('About this room', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        widget.room.description.isEmpty
                            ? 'Experience comfort and luxury in this beautifully appointed room. Perfect for both leisure and business travelers.'
                            : widget.room.description,
                        style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                      ),
                    ],
                  ),
                ),

                if (widget.room.facilities.isNotEmpty) ...[
                  const Divider(height: 1, thickness: 8),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Amenities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: widget.room.facilities.map((f) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getFacilityIcon(f), size: 20, color: Colors.blue[700]),
                                    const SizedBox(width: 8),
                                    Text(f, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              )).toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 1, thickness: 8),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Guest Reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          TextButton(onPressed: () {}, child: const Text('See all')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...reviews.take(3).map((r) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _buildReviewCard(r))),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹${widget.room.pricePerNight.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const Text('per night', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: widget.room.status == 'available'
                      ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(room: widget.room)))
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.room.status == 'available' ? 'Book Now' : 'Not Available',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: Colors.blue[700]),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.blue[700], child: Text(review['avatar'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(review['date'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                    Text(review['rating'].toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review['comment'], style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4)),
        ],
      ),
    );
  }

  IconData _getFacilityIcon(String facility) {
    switch (facility.toLowerCase()) {
      case 'wifi': return Icons.wifi;
      case 'tv': return Icons.tv;
      case 'ac': return Icons.ac_unit;
      case 'mini bar': return Icons.local_bar;
      case 'safe': return Icons.lock;
      case 'room service': return Icons.room_service;
      case 'balcony': return Icons.balcony;
      case 'ocean view':
      case 'mountain view': return Icons.landscape;
      case 'bathtub': return Icons.bathtub;
      case 'shower': return Icons.shower;
      case 'hair dryer': return Icons.dry;
      case 'coffee maker': return Icons.coffee;
      case 'work desk': return Icons.desk;
      default: return Icons.check_circle_outline;
    }
  }
}