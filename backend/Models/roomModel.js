const mongoose = require("mongoose");

const roomSchema = new mongoose.Schema(
  {
    roomNo: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },

    type: {
      type: String,
      enum: ["Standard", "Deluxe", "Suite", "Premium"],
      required: true,
    },

    capacity: {
      type: Number,
      required: true,
      min: 1,
      max: 10,
    },

    pricePerNight: {
      type: Number,
      required: true,
      min: 0,
    },

    status: {
      type: String,
      enum: ["available", "occupied", "maintenance", "reserved"],
      default: "available",
    },

    isAllocated: {
      type: Boolean,
      default: false,
    },

    members: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Customer",
      },
    ],

    facilities: {
      type: [String],
      default: [],
    },

    floor: {
      type: Number,
      min: 0,
    },

    description: {
      type: String,
      trim: true,
      maxlength: 500,
    },
    images: [
      {
        url: { type: String, required: true },
        public_id: { type: String, required: true },
      },
    ],
  },
  {
    timestamps: true,
    versionKey: false,
  },
);

module.exports = mongoose.model("Room", roomSchema);
