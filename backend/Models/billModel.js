const mongoose = require("mongoose");

const billSchema = new mongoose.Schema({
  billId: { type: String, unique: true, required: true },
  table: { type: String, required: true },

  user: {
    fullName: {
      type: String,
      trim: true,
      default: "Walk-in / Guest",
    },
    mobile: {
      type: String,
      trim: true,
      default: "1234567890",
    },
  },

  orders: [
    {
      orderId: { type: String, required: true },
      items: [
        {
          name: { type: String, required: true },
          customization: { type: String, required: true },
          quantity: { type: Number, required: true },
          price: { type: Number, required: true },
        },
      ],
      total: { type: Number, required: true },
      status: { type: String, required: true },
      timestamp: { type: Date, required: true },
    },
  ],

  totalAmount: { type: Number, required: true },
  isGstApplied: { type: Boolean, required: true },

  paymentMethod: { type: String , required : false , default:"NONE"},
  transactionId: { type: String , required : false , default:"NONE"},

  status: { type: String, default: "Pending" },

  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});



const Bill = mongoose.model("Bill", billSchema);

module.exports = Bill;
