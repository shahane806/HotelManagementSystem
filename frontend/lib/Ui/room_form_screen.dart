import 'dart:io';
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

  final roomNoCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final floorCtrl = TextEditingController();

  String roomType = 'Standard';
  List<File> images = [];

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      roomNoCtrl.text = widget.room!.roomNo;
      priceCtrl.text = widget.room!.pricePerNight.toString();
      floorCtrl.text = widget.room!.floor.toString();
      roomType = widget.room!.type;
    }
  }

  Future<void> pickImages() async {
    final picked = await picker.pickMultiImage(imageQuality: 80);
    print("Om Shahane : ${images}");
    if (picked.isNotEmpty) {
      setState(() {
        images = picked.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.room == null) {
      await api.createRoom(
        roomNo: roomNoCtrl.text,
        type: roomType,
        capacity: 2,
        pricePerNight: double.parse(priceCtrl.text),
        floor: int.parse(floorCtrl.text),
        description: '',
        facilities: [],
        images: images,
      );
    } else {
      await api.updateRoom(
        id: widget.room!.id,
        roomNo: roomNoCtrl.text,
        price: double.parse(priceCtrl.text),
        floor: int.parse(floorCtrl.text),
        images: images.isEmpty ? null : images,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room == null ? 'Create Room' : 'Update Room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: roomNoCtrl,
                decoration: const InputDecoration(labelText: 'Room Number'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price / Night'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: floorCtrl,
                decoration: const InputDecoration(labelText: 'Floor'),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField(
                value: roomType,
                decoration: const InputDecoration(labelText: 'Room Type'),
                items: ['Normal', 'Standard', 'Deluxe', 'Suite']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => roomType = v!),
              ),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Upload Images'),
                onPressed: pickImages,
              ),

              Wrap(
                spacing: 8,
                children: images
                    .map(
                      (img) => Image.file(img, height: 80, width: 80),
                    )
                    .toList(),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: submit,
                child: const Text('Save Room'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
