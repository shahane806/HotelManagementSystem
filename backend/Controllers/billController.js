const { v4: uuidv4 } = require('uuid');
const bill = require('../Models/billModel');
const Order = require('../Models/orderModel');
const { json } = require('express');
const createBill = async (req, res) => {
  console.log("hei");
  const { table,  orders, totalAmount, isGstApplied } = req.body;
  console.log(table)

  try {
    if (!table || !orders || !totalAmount || isGstApplied === undefined) {
      console.log("Missing required fielsds");
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Apply GST if isGstApplied is true
    let finalAmount = totalAmount;
    if (isGstApplied) {
      // const gst = (18 / 100) * totalAmount;
      const gst = 0;
      finalAmount += gst;
    }
    console.log("hello");
    const billId = uuidv4();
    const newBill = new bill({
      billId,
      table,
      // user,
      orders,
      totalAmount: finalAmount, // Save updated amount with GST
      isGstApplied,
      status: 'Pending'
    });

    await newBill.save();
    console.log("HELLO");
    res.status(201).json({ message: 'Bill stored successfully', billId, totalAmount: finalAmount });
  } catch (error) {
    console.error('Error storing bill:', error);
    res.status(500).json({ message: 'Failed to store bill', error: error.message });
  }
};
const getAllBills = async (req, res) => {
  try {
    const bills = await bill.find();
    console.log(bills)
    res.status(200).json({
      success: true,
      data: bills
    });
  } catch (error) {
    console.error('Error fetching bills:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bills',
      error: error.message
    });
  }
};
const updateBillStatus = async (req, res) => {
  const { billId, status, paymentMethod } = req.body;

  try {
    const billToUpdate = await bill.findOne({ billId });
    if (!billToUpdate) {
      return res.status(404).json({ message: 'Bill not found' });
    }

    billToUpdate.status = status;
    billToUpdate.paymentMethod = paymentMethod;
    billToUpdate.updatedAt = new Date();
    await billToUpdate.save();

    // 🔥 THIS WAS MISSING
    const orderIds = billToUpdate.orders.map(o => o.orderId);
    console.log(`Om Shahane : ${orderIds}`);
    const updatedOrders = await Order.updateMany(
      { _id: { $in: orderIds } },
      { $set: { bill_status: "Paid" } }
    );
    res.status(200).json({ message: 'Bill and orders updated successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update bill status' });
  }
};

module.exports = {createBill,getAllBills,updateBillStatus}