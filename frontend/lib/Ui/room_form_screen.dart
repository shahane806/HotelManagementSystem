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

class _RoomFormScreenState extends State<RoomFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final api = ApiServiceRooms();
  final picker = ImagePicker();

  late TextEditingController roomNoCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController floorCtrl;
  late TextEditingController descriptionCtrl;
  late TextEditingController capacityCtrl;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String roomType = 'Standard';
  List<XFile> images = [];
  List<String> selectedFacilities = [];
  bool isLoading = false;
  int _currentStep = 0;

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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Please add at least one room image')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (widget.room == null) {
        await api.createRoom(
          roomNo: roomNoCtrl.text.trim(),
          type: roomType,
          capacity: int.parse(capacityCtrl.text),
          pricePerNight: double.parse(priceCtrl.text),
          floor: int.parse(floorCtrl.text),
          description: descriptionCtrl.text.trim(),
          facilities: selectedFacilities,
          images: images,
        );
      } else {
        await api.updateRoom(
          id: widget.room!.id,
          roomNo: roomNoCtrl.text.trim(),
          price: double.parse(priceCtrl.text),
          floor: int.parse(floorCtrl.text),
          description: descriptionCtrl.text.trim(),
          images: images.isEmpty ? null : images,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.room == null
                      ? 'Room created successfully!'
                      : 'Room updated successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey[900],
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                widget.room == null ? 'Add New Room' : 'Edit Room',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.indigo.shade50,
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Progress Indicator
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildProgressStep(0, 'Details', Icons.info_outline_rounded),
                          Expanded(child: _buildProgressLine(0)),
                          _buildProgressStep(1, 'Photos', Icons.photo_camera_outlined),
                          Expanded(child: _buildProgressLine(1)),
                          _buildProgressStep(2, 'Amenities', Icons.star_border_rounded),
                        ],
                      ),
                    ),

                    // Basic Info
                    _buildAnimatedSection(
                      delay: 0,
                      child: _buildSection(
                        title: 'Basic Information',
                        subtitle: 'Enter room details and pricing',
                        icon: Icons.edit_note_rounded,
                        iconColor: Colors.blue,
                        children: [
                          _buildTextField(
                            roomNoCtrl,
                            'Room Number',
                            Icons.meeting_room_outlined,
                            'e.g., 101, A-205',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  capacityCtrl,
                                  'Capacity',
                                  Icons.people_outline_rounded,
                                  'Max guests',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  floorCtrl,
                                  'Floor',
                                  Icons.layers_outlined,
                                  'Floor no.',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildModernDropdown(),
                        ],
                      ),
                    ),

                    // Pricing
                    _buildAnimatedSection(
                      delay: 100,
                      child: _buildSection(
                        title: 'Pricing',
                        subtitle: 'Set competitive rates',
                        icon: Icons.currency_rupee_rounded,
                        iconColor: Colors.green,
                        children: [
                          _buildTextField(
                            priceCtrl,
                            'Price per Night',
                            Icons.attach_money_rounded,
                            'Enter amount in ₹',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),

                    // Description
                    _buildAnimatedSection(
                      delay: 200,
                      child: _buildSection(
                        title: 'Description',
                        subtitle: 'Highlight key features',
                        icon: Icons.description_outlined,
                        iconColor: Colors.orange,
                        children: [
                          _buildTextField(
                            descriptionCtrl,
                            'Room Description',
                            Icons.edit_outlined,
                            'Describe this room...',
                            maxLines: 5,
                          ),
                        ],
                      ),
                    ),

                    // Facilities
                    _buildAnimatedSection(
                      delay: 300,
                      child: _buildSection(
                        title: 'Amenities & Facilities',
                        subtitle: 'Select available features',
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: Colors.purple,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: availableFacilities.map((facility) {
                              final selected = selectedFacilities.contains(facility);
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    selected
                                        ? selectedFacilities.remove(facility)
                                        : selectedFacilities.add(facility);
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: selected ? Colors.indigo.shade50 : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected ? Colors.indigo.shade300 : Colors.grey.shade300,
                                      width: selected ? 2 : 1,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: Colors.indigo.withOpacity(0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                        size: 20,
                                        color: selected ? Colors.indigo.shade700 : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        facility,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                          color: selected ? Colors.indigo.shade900 : Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // Images
                    _buildAnimatedSection(
                      delay: 400,
                      child: _buildSection(
                        title: 'Room Photos',
                        subtitle: 'Add high-quality images',
                        icon: Icons.photo_library_outlined,
                        iconColor: Colors.pink,
                        children: [
                          InkWell(
                            onTap: pickImages,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.indigo.shade200,
                                  width: 2,
                                  strokeAlign: BorderSide.strokeAlignInside,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 40,
                                      color: Colors.indigo.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Add Photos',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to select multiple images',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
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
                                            return Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Image.memory(
                                                snapshot.data!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                            );
                                          }
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => removeImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade500,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (index == 0)
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.shade700,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Cover',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ] else if (widget.room != null && widget.room!.images.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: Colors.amber.shade700),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Current images will be kept unless you add new ones',
                                        style: TextStyle(
                                          color: Colors.amber.shade900,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: isLoading ? null : submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: 0,
              shadowColor: Colors.indigo.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.room == null ? Icons.add_rounded : Icons.check_rounded,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.room == null ? 'Create Room' : 'Update Room',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? Colors.indigo.shade600 : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? Colors.white : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.indigo.shade900 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(int step) {
    final isActive = _currentStep > step;
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 30, left: 8, right: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.indigo.shade600 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildAnimatedSection({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String hint, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.indigo.shade600, size: 20),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.indigo.shade400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      ),
    );
  }

  Widget _buildModernDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: roomType,
        decoration: InputDecoration(
          labelText: 'Room Type',
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.hotel_rounded, color: Colors.indigo.shade600, size: 20),
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[700]),
        dropdownColor: Colors.white,
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        items: roomTypes.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(
              type,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) => setState(() => roomType = value!),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    roomNoCtrl.dispose();
    priceCtrl.dispose();
    floorCtrl.dispose();
    descriptionCtrl.dispose();
    capacityCtrl.dispose();
    super.dispose();
  }
}