const mongoose = require("mongoose");

const orderSchema = new mongoose.Schema({
  id: { type: String, required: true },
  table: { type: String, required: true },
  items: [
    {
      name: { type: String, required: true },
      customization: { type: String },
      quantity: { type: Number, required: true },
      price: { type: Number, required: true },
    },
  ],
  total: { type: Number, required: true },
  status: {
    type: String,
    enum: ["Pending", "Preparing", "Ready", "Served"],
    default:"Pending",
    required: true,
  },
  bill_status:{
    type:String,
    enum:["Pending","Paid"],
    default:"Pending",
    required: false,
  },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Order", orderSchema);
