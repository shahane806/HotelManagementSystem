const mongoose = require("mongoose");

const utilitySchema = new mongoose.Schema({
  utilityName: {
    type: String,
    required: true,
    enum: ["Table", "Room", "Menu", "Amenity"], 
    unique: true,
  },
  utilityItems: [
    {
      type: mongoose.Schema.Types.Mixed, 
      required: true,
    },
  ],
  createdUtility: {
    type: Date,
    default: Date.now,
  },
  updatedUtility: {
    type: Date,
    default: Date.now,
  },
});

utilitySchema.pre("save", function (next) {
  this.updatedUtility = Date.now();
  next();
});

const UtilityModel = mongoose.model("Utilities", utilitySchema);

module.exports = UtilityModel;