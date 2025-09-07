const { v4: uuidv4 } = require('uuid');
const bill = require('../Models/billModel');
const createBill = async (req, res) => {
  console.log("hei")
  const { table, user, orders, totalAmount, isGstApplied } = req.body;
  console.log(req.body)
  try {
    if (!table || !user || !orders || !totalAmount || isGstApplied === undefined) {
        console.log("Missing required fielsds");
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const billId = uuidv4();
    const newBill = new bill({
      billId,
      table,
      user,
      orders,
      totalAmount,
      isGstApplied,
      status: 'Pending'
    });

    await newBill.save();
    res.status(201).json({ message: 'Bill stored successfully', billId });
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
  console.log("Updating bill status");
  const { billId, status, paymentMethod } = req.body;
  console.log("Request body:", req.body);

  try {
    if (!billId || !status) {
      console.log("Missing required fields: billId or status");
      return res.status(400).json({ message: 'Missing required fields: billId and status are required' });
    }

    const billToUpdate = await bill.findOne({ billId });
    if (!billToUpdate) {
      console.log("Bill not found:", billId);
      return res.status(404).json({ message: 'Bill not found' });
    }

    billToUpdate.status = status;
    if (paymentMethod) {
      billToUpdate.paymentMethod = paymentMethod;
    }
    billToUpdate.updatedAt = new Date();

    await billToUpdate.save();

    res.status(200).json({ message: 'Bill status updated successfully', billId, status });
  } catch (error) {
    console.error('Error updating bill status:', error);
    res.status(500).json({ message: 'Failed to update bill status', error: error.message });
  }
};
module.exports = {createBill,getAllBills,updateBillStatus}