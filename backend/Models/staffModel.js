const mongoose = require("mongoose");
const staffSchemas = new mongoose.Schema(
  {
     userId: { type: String, required: true, unique: true , index: true},
  fullName: { type: String, required: true },
  email: { type: String, required: true },
  mobile: { type: String, required: true },
  aadhaarNumber: { type: String, required: true },
    role: {
      type: String,
      required: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Staff", staffSchemas);
