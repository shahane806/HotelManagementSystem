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
const fetchRooms = async (req, res) => {};

module.exports = { createRoom, fetchRooms };
