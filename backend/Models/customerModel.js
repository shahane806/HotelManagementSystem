const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  fullName: { type: String, required: true },
  email: { type: String, required: true },
  mobile: { type: String, required: true },
  aadhaarNumber: { type: String, required: true },
}, { timestamps: true });

module.exports = mongoose.model('Customer', customerSchema);