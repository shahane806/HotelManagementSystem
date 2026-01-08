const Room = require("../Models/roomModel");

// 1. Create room
const createRoom = async (req, res) => {
  const {
    roomNo,
    type,
    capacity,
    pricePerNight,
    facilities,
    floor,
    description,
  } = req.body;

  if (!roomNo || !type || !capacity || !pricePerNight || !floor) {
    return res.status(400).json({ message: "All fields are required!" });
  }

  let images = [];

  if (req.files && req.files.length > 0) {
    console.log("Files uploaded:", req.files);
    images = req.files.map((file) => ({
      url: file.path,
      public_id: file.filename,
    }));
  } else if (req.file) {
    console.log("File uploaded:", req.file);
    images = [
      {
        url: req.file.path,
        public_id: req.file.filename,
      },
    ];
  }

  try {
    const newRoom = await Room.create({
      roomNo,
      type,
      capacity: parseInt(capacity),
      pricePerNight: parseFloat(pricePerNight),
      facilities: facilities ? facilities.split(",").map((f) => f.trim()) : [],
      floor: parseInt(floor),
      description,
      images,
    });

    return res.status(201).json({
      message: "Room created successfully!",
      room: newRoom,
    });
  } catch (error) {
    console.error("Error creating room:", error);
    return res.status(500).json({
      message: "Failed to create room",
      error: error.message,
    });
  }
};
// 2. Fetch rooms
const fetchRooms = async (req, res) => {
  try {
    const { status, type, floor, minPrice, maxPrice } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    // Build filter object
    let filter = {};
    
    if (status) filter.status = status;
    if (type) filter.type = type;
    if (floor) filter.floor = parseInt(floor);
    if (minPrice || maxPrice) {
      filter.pricePerNight = {};
      if (minPrice) filter.pricePerNight.$gte = parseFloat(minPrice);
      if (maxPrice) filter.pricePerNight.$lte = parseFloat(maxPrice);
    }

    const rooms = await Room.find(filter)
      .populate('members', 'name email phone')
      .skip(skip)
      .limit(limit)
      .sort({ createdAt: -1 });

    const totalRooms = await Room.countDocuments(filter);

    return res.status(200).json({
      success: true,
      rooms,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalRooms / limit),
        totalRooms,
        limit,
      },
    });
  } catch (error) {
    console.error("Error fetching rooms:", error);
    return res.status(500).json({
      message: "Failed to fetch rooms",
      error: error.message,
    });
  }
};

// 3. Get room by ID
const getRoomById = async (req, res) => {
  try {
    const { id } = req.params;

    const room = await Room.findById(id).populate('members', 'name email phone');

    if (!room) {
      return res.status(404).json({ message: "Room not found" });
    }

    return res.status(200).json({
      success: true,
      room,
    });
  } catch (error) {
    console.error("Error fetching room:", error);
    return res.status(500).json({
      message: "Failed to fetch room",
      error: error.message,
    });
  }
};

// 4. Update room
const updateRoom = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      roomNo,
      type,
      capacity,
      pricePerNight,
      facilities,
      floor,
      description,
      status,
    } = req.body;

    const room = await Room.findById(id);

    if (!room) {
      return res.status(404).json({ message: "Room not found" });
    }

    // Update fields if provided
    if (roomNo) room.roomNo = roomNo;
    if (type) room.type = type;
    if (capacity) room.capacity = parseInt(capacity);
    if (pricePerNight) room.pricePerNight = parseFloat(pricePerNight);
    if (facilities) room.facilities = facilities.split(",").map((f) => f.trim());
    if (floor !== undefined) room.floor = parseInt(floor);
    if (description) room.description = description;
    if (status) room.status = status;

    // Handle new images if uploaded
    if (req.files && req.files.length > 0) {
      const newImages = req.files.map((file) => ({
        url: file.path,
        public_id: file.filename,
      }));
      room.images = [...room.images, ...newImages];
    } else if (req.file) {
      room.images.push({
        url: req.file.path,
        public_id: req.file.filename,
      });
    }

    await room.save();

    return res.status(200).json({
      message: "Room updated successfully!",
      room,
    });
  } catch (error) {
    console.error("Error updating room:", error);
    return res.status(500).json({
      message: "Failed to update room",
      error: error.message,
    });
  }
};

// 5. Delete room
const deleteRoom = async (req, res) => {
  try {
    const { id } = req.params;

    const room = await Room.findById(id);

    if (!room) {
      return res.status(404).json({ message: "Room not found" });
    }

    // Check if room is occupied
    if (room.status === "occupied" || room.isAllocated) {
      return res.status(400).json({
        message: "Cannot delete an occupied or allocated room",
      });
    }

    await Room.findByIdAndDelete(id);

    return res.status(200).json({
      message: "Room deleted successfully!",
    });
  } catch (error) {
    console.error("Error deleting room:", error);
    return res.status(500).json({
      message: "Failed to delete room",
      error: error.message,
    });
  }
};

// 6. Update room status
const updateRoomStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status || !["available", "occupied", "maintenance", "reserved"].includes(status)) {
      return res.status(400).json({
        message: "Valid status is required (available, occupied, maintenance, reserved)",
      });
    }

    const room = await Room.findByIdAndUpdate(
      id,
      { status },
      { new: true, runValidators: true }
    );

    if (!room) {
      return res.status(404).json({ message: "Room not found" });
    }

    return res.status(200).json({
      message: "Room status updated successfully!",
      room,
    });
  } catch (error) {
    console.error("Error updating room status:", error);
    return res.status(500).json({
      message: "Failed to update room status",
      error: error.message,
    });
  }
};

module.exports = {
  createRoom,
  fetchRooms,
  getRoomById,
  updateRoom,
  deleteRoom,
  updateRoomStatus,
};
