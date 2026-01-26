const { v4: uuidv4 } = require("uuid");
const bill = require("../Models/billModel");
const Order = require("../Models/orderModel");
const { json } = require("express");
const createBill = async (req, res) => {
  console.log("hei");
  const { table, orders, totalAmount, isGstApplied } = req.body;
  console.log(table);

  try {
    if (!table || !orders || !totalAmount || isGstApplied === undefined) {
      console.log("Missing required fielsds");
      return res.status(400).json({ message: "Missing required fields" });
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
      status: "Pending",
    });

    await newBill.save();
    console.log("HELLO");
    res
      .status(201)
      .json({
        message: "Bill stored successfully",
        billId,
        totalAmount: finalAmount,
      });
  } catch (error) {
    console.error("Error storing bill:", error);
    res
      .status(500)
      .json({ message: "Failed to store bill", error: error.message });
  }
};
const getAllBills = async (req, res) => {
  try {
    const bills = await bill.find();
    console.log(bills);
    res.status(200).json({
      success: true,
      data: bills,
    });
  } catch (error) {
    console.error("Error fetching bills:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch bills",
      error: error.message,
    });
  }
};
const getAnalytics = async (req, res) => {
  try {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    const monthStart = new Date(
      todayStart.getFullYear(),
      todayStart.getMonth(),
      1
    );

    // ─── Today's Paid Bills ─────────────────────────────────────
    const todayBills = await bill.find({
      status: "Paid",
      updatedAt: { $gte: todayStart, $lte: todayEnd },
    });

    let todayTotal = 0;
    let todayCash = 0;
    let todayOnline = 0;

    todayBills.forEach((b) => {
      todayTotal += b.totalAmount || 0;
      if (b.paymentMethod?.toLowerCase() === "cash") {
        todayCash += b.totalAmount || 0;
      } else {
        todayOnline += b.totalAmount || 0;
      }
    });

    // ─── This Month's Paid Bills ────────────────────────────────
    const monthBills = await bill.find({
      status: "Paid",
      updatedAt: { $gte: monthStart },
    });

    let monthTotal = 0;
    let monthCash = 0;
    let monthOnline = 0;

    monthBills.forEach((b) => {
      monthTotal += b.totalAmount || 0;
      if (b.paymentMethod?.toLowerCase() === "cash") {
        monthCash += b.totalAmount || 0;
      } else {
        monthOnline += b.totalAmount || 0;
      }
    });

    // ─── Pending Bills Count ────────────────────────────────────
    const pendingCount = await bill.countDocuments({ status: "Pending" });

    // ─── Recent Paid Bills (last 10) with mobile ────────────────
    const recentBills = await bill
      .find({ status: "Paid" })
      .sort({ updatedAt: -1 })
      .limit(10)
      .select("billId table totalAmount paymentMethod updatedAt user");
    const responseData = {
      success: true,
      data: {
        today: {
          total: todayTotal,
          cash: todayCash,
          online: todayOnline,
          billCount: todayBills.length,  // ← this was missing
        },
        month: {
          total: monthTotal,
          cash: monthCash,
          online: monthOnline,
          billCount: monthBills.length,  // ← this was missing
        },
        pendingCount,
        recentBills: recentBills.map((b) => ({
          billId: b.billId,
          table: b.table,
          amount: b.totalAmount,
          paymentMethod: b.paymentMethod || "Unknown",
          date: b.updatedAt.toISOString(),
          mobile: b.user?.mobile || "N/A",
        })),
      },
    };

    console.log("Analytics response sent:", JSON.stringify(responseData, null, 2));

    res.status(200).json(responseData);
  } catch (error) {
    console.error("Analytics error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch analytics",
      error: error.message,
    });
  }
};
const updateBillStatus = async (req, res) => {
  const { billId, status, paymentMethod, mobile } = req.body;

  console.log('updateBillStatus called with:', { billId, status, paymentMethod, mobile });

  try {
    const billToUpdate = await bill.findOne({ billId });
    if (!billToUpdate) {
      return res.status(404).json({ message: "Bill not found" });
    }

    // Update main fields
    billToUpdate.status = status;
    if (paymentMethod) billToUpdate.paymentMethod = paymentMethod;

    // Update mobile INSIDE user object
    if (mobile && mobile.trim()) {
      billToUpdate.user = billToUpdate.user || {}; // prevent null overwrite
      billToUpdate.user.mobile = mobile.trim();
      billToUpdate.markModified('user'); // ← tells Mongoose sub-doc changed
      console.log(`Saving mobile: ${mobile.trim()} for bill ${billId}`);
    } else {
      console.log('No mobile received for bill ' + billId);
    }

    billToUpdate.updatedAt = new Date();

    await billToUpdate.save();

    // Update related orders
    const orderIds = billToUpdate.orders.map((o) => o.orderId).filter(Boolean);
    console.log(`Updating orders for bill ${billId}:`, orderIds);

    if (orderIds.length > 0) {
      await Order.updateMany(
        { _id: { $in: orderIds } },
        { $set: { bill_status: "Paid" } }
      );
    }

    res.status(200).json({
      success: true,
      message: "Bill and orders updated successfully",
      updatedBill: billToUpdate, // optional: return updated doc for debugging
    });
  } catch (error) {
    console.error("Update bill status error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update bill status",
      error: error.message,
    });
  }
};
const generateReport = async (req, res) => {
  const { startDate, endDate, paymentMethod } = req.body;

  try {
    if (!startDate || !endDate) {
      return res.status(400).json({
        success: false,
        message: 'startDate and endDate are required (YYYY-MM-DD format)',
      });
    }

    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999); // Include whole end day

    if (isNaN(start) || isNaN(end)) {
      return res.status(400).json({ success: false, message: 'Invalid date format' });
    }

    const query = {
      status: 'Paid',
      updatedAt: { $gte: start, $lte: end },
    };

    if (paymentMethod) {
      query.paymentMethod = { $regex: new RegExp(`^${paymentMethod}$`, 'i') };
    }

    const reports = await bill
      .find(query)
      .select('billId table totalAmount paymentMethod updatedAt user')  // ← THIS IS THE FIX
      .sort({ updatedAt: -1 });
    console.log(`Om Shahane : ${reports}` )

    const total = reports.reduce((sum, b) => sum + (b.totalAmount || 0), 0);
    const cash = reports
      .filter((b) => b.paymentMethod?.toLowerCase() === 'cash')
      .reduce((sum, b) => sum + (b.totalAmount || 0), 0);
    const online = total - cash;

    res.status(200).json({
      success: true,
      data: {
        period: { startDate, endDate },
        total,
        cash,
        online,
        billCount: reports.length,
        bills: reports.map((b) => ({
          billId: b.billId,
          table: b.table,
          amount: b.totalAmount,
          paymentMethod: b.paymentMethod || "Unknown",
          date: b.updatedAt.toISOString(),
          mobile: b.user?.mobile || "N/A",   // ← now mobile will come
        })),
      },
    });
  } catch (error) {
    console.error('Report generation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate report',
      error: error.message,
    });
  }
};
module.exports = { createBill, getAllBills, updateBillStatus, getAnalytics ,generateReport};
