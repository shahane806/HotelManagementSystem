import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/hotel_room_model.dart';
import '../services/apiServicesRoom.dart';

class RoomFormScreen extends StatefulWidget {
  final HotelRoomModel? room;

  const RoomFormScreen({super.key, this.room});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final api = ApiServiceRooms();
  final picker = ImagePicker();

  late TextEditingController roomNoCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController floorCtrl;
  late TextEditingController descriptionCtrl;
  late TextEditingController capacityCtrl;

  String roomType = 'Standard';
  List<XFile> images = []; // Only one list: XFile works everywhere
  List<String> selectedFacilities = [];
  bool isLoading = false;

  final List<String> roomTypes = ['Standard', 'Deluxe', 'Suite', 'Premium'];
  final List<String> availableFacilities = [
    'WiFi',
    'TV',
    'AC',
    'Mini Bar',
    'Safe',
    'Room Service',
    'Balcony',
    'Ocean View',
    'Mountain View',
    'Bathtub',
    'Shower',
    'Hair Dryer',
    'Coffee Maker',
    'Work Desk',
  ];

  @override
  void initState() {
    super.initState();
    roomNoCtrl = TextEditingController(text: widget.room?.roomNo ?? '');
    priceCtrl = TextEditingController(text: widget.room?.pricePerNight.toStringAsFixed(0) ?? '');
    floorCtrl = TextEditingController(text: widget.room?.floor.toString() ?? '1');
    descriptionCtrl = TextEditingController(text: widget.room?.description ?? '');
    capacityCtrl = TextEditingController(text: widget.room?.capacity.toString() ?? '2');

    if (widget.room != null) {
      roomType = widget.room!.type;
      selectedFacilities = List.from(widget.room!.facilities);
    }
  }

  Future<void> pickImages() async {
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      setState(() {
        images.addAll(picked);
      });
    }
  }

  void removeImage(int index) {
    setState(() {
      images.removeAt(index);
    });
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (images.isEmpty && widget.room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one room image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (widget.room == null) {
        print("Om Shahane : ${images}");
        await api.createRoom(
          roomNo: roomNoCtrl.text.trim(),
          type: roomType,
          capacity: int.parse(capacityCtrl.text),
          pricePerNight: double.parse(priceCtrl.text),
          floor: int.parse(floorCtrl.text),
          description: descriptionCtrl.text.trim(),
          facilities: selectedFacilities,
          images: images, // Pass XFile list directly
        );
      } else {
        print("Om Shahane : ${images}");
        await api.updateRoom(
          id: widget.room!.id,
          roomNo: roomNoCtrl.text.trim(),
          price: double.parse(priceCtrl.text),
          floor: int.parse(floorCtrl.text),
          description: descriptionCtrl.text.trim(),
          images: images.isEmpty ? null : images, // Same for update
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.room == null
                ? 'Room created successfully!'
                : 'Room updated successfully!'),
            backgroundColor: Colors.green[700],
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          widget.room == null ? 'Add New Room' : 'Edit Room',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Basic Info
            _buildSection(
              title: 'Basic Information',
              icon: Icons.info_outline,
              children: [
                _buildTextField(roomNoCtrl, 'Room Number', Icons.door_front_door),
                const SizedBox(height: 16),
                _buildTextField(capacityCtrl, 'Guest Capacity', Icons.people,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField(floorCtrl, 'Floor Number', Icons.layers,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildDropdown(),
              ],
            ),

            const SizedBox(height: 24),

            // Pricing
            _buildSection(
              title: 'Pricing',
              icon: Icons.attach_money,
              children: [
                _buildTextField(priceCtrl, 'Price per Night (₹)', Icons.currency_rupee,
                    keyboardType: TextInputType.number),
              ],
            ),

            const SizedBox(height: 24),

            // Description
            _buildSection(
              title: 'Description',
              icon: Icons.edit_note,
              children: [
                _buildTextField(descriptionCtrl, 'Describe this room...', Icons.description,
                    maxLines: 5),
              ],
            ),

            const SizedBox(height: 24),

            // Facilities
            _buildSection(
              title: 'Amenities & Facilities',
              icon: Icons.check_circle_outline,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: availableFacilities.map((facility) {
                    final selected = selectedFacilities.contains(facility);
                    return FilterChip(
                      label: Text(facility),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          selected
                              ? selectedFacilities.remove(facility)
                              : selectedFacilities.add(facility);
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.indigo[100],
                      checkmarkColor: Colors.indigo[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Images
            _buildSection(
              title: 'Room Photos',
              icon: Icons.photo_library,
              children: [
                Center(
                  child: OutlinedButton.icon(
                    onPressed: pickImages,
                    icon: const Icon(Icons.add_a_photo, size: 28),
                    label: const Text('Add Photos', style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: Colors.indigo[700]!),
                    ),
                  ),
                ),
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: FutureBuilder<Uint8List>(
                              future: images[index].readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  );
                                }
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(child: CircularProgressIndicator()),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ] else if (widget.room != null && widget.room!.images.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Current images will be kept unless you add new ones',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: isLoading ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[700],
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.room == null ? 'Create Room' : 'Update Room',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.indigo[700], size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo[600]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.indigo[700]!, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: roomType,
      decoration: InputDecoration(
        labelText: 'Room Type',
        prefixIcon: const Icon(Icons.hotel, color: Colors.indigo),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      items: roomTypes
          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      onChanged: (value) => setState(() => roomType = value!),
    );
  }

  @override
  void dispose() {
    roomNoCtrl.dispose();
    priceCtrl.dispose();
    floorCtrl.dispose();
    descriptionCtrl.dispose();
    capacityCtrl.dispose();
    super.dispose();
  }
}