const mongoose = require('mongoose');

const billSchema = new mongoose.Schema({
  billId: { type: String, unique: true, required: true },
  table: { type: String, required: true },
  // user: {
  //   id: { type: String, required: true },
  //   fullName: { type: String, required: true },
  //   email: { type: String, required: true },
  //   mobile: { type: String, required: true }
  // },
  orders: [{
    orderId: { type: String, required: true },
    items: [{
      name: { type: String, required: true },
      customization: { type: String, required: true },
      quantity: { type: Number, required: true },
      price: { type: Number, required: true }
    }],
    total: { type: Number, required: true },
    status: { type: String, required: true },
    timestamp: { type: Date, required: true }
  }],
  totalAmount: { type: Number, required: true },
  isGstApplied: { type: Boolean, required: true },
  status: { type: String, default: 'Pending' },
  paymentMethod: { type: String },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const Bill = mongoose.model('Bill', billSchema);

module.exports = Bill;