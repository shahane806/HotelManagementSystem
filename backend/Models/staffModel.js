const mongoose = require("mongoose");

const staffSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    fullName: { type: String, required: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    mobile: { type: String, required: true },
    aadhaarNumber: { type: String, required: true },
    role: { type: String, required: false },
    password: { type: String, required: false, select: false }, // Do not return password by default
    resetPasswordToken: { type: String },
    resetPasswordExpires: { type: Date },
  },
  { timestamps: true },
);

module.exports = mongoose.model("StaffModel", staffSchema);
