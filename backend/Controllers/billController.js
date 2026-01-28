const { v4: uuidv4 } = require("uuid");
const bill = require("../Models/billModel");
const Order = require("../Models/orderModel");

/* ───────────────────────── CREATE BILL ───────────────────────── */
const createBill = async (req, res) => {
  const { table, orders, totalAmount, isGstApplied } = req.body;

  try {
    if (!table || !orders || !totalAmount || isGstApplied === undefined) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    let finalAmount = totalAmount;
    if (isGstApplied) {
      const gst = 0;
      finalAmount += gst;
    }

    const billId = uuidv4();

    const newBill = new bill({
      billId,
      table,
      orders,
      totalAmount: finalAmount,
      isGstApplied,
      status: "Pending",
    });

    await newBill.save();

    res.status(201).json({
      success: true,
      billId,
      totalAmount: finalAmount,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to store bill",
      error: error.message,
    });
  }
};

/* ───────────────────────── GET ALL BILLS ───────────────────────── */
const getAllBills = async (req, res) => {
  try {
    const bills = await bill.find();
    res.status(200).json({ success: true, data: bills });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch bills",
      error: error.message,
    });
  }
};

/* ───────────────────────── ANALYTICS ───────────────────────── */
const getAnalytics = async (req, res) => {
  try {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    const monthStart = new Date(
      todayStart.getFullYear(),
      todayStart.getMonth(),
      1,
    );

    const todayBills = await bill.find({
      status: "Paid",
      updatedAt: { $gte: todayStart, $lte: todayEnd },
    });

    const monthBills = await bill.find({
      status: "Paid",
      updatedAt: { $gte: monthStart },
    });

    const calc = (list) =>
      list.reduce(
        (acc, b) => {
          acc.total += b.totalAmount || 0;
          if (b.paymentMethod?.toLowerCase() === "cash") {
            acc.cash += b.totalAmount || 0;
          } else {
            acc.online += b.totalAmount || 0;
          }
          return acc;
        },
        { total: 0, cash: 0, online: 0 },
      );

    const today = calc(todayBills);
    const month = calc(monthBills);

    const pendingCount = await bill.countDocuments({ status: "Pending" });

    const recentBills = await bill
      .find({ status: "Paid" })
      .sort({ updatedAt: -1 })
      .limit(10)
      .select("billId table totalAmount paymentMethod transactionId status updatedAt user orders isGstApplied");

    res.status(200).json({
      success: true,
      data: {
        today: { ...today, billCount: todayBills.length },
        month: { ...month, billCount: monthBills.length },
        pendingCount,
        bills: recentBills.map((b) => ({

          billId: b.billId,
          table: b.table,
          amount: b.totalAmount,
          paymentMethod: b.paymentMethod || "Unknown",
          date: b.updatedAt.toISOString(),
          mobile: b.user?.mobile || "N/A",
          orders: Array.isArray(b.orders) ? b.orders : [],
          isGstApplied: b.isGstApplied ?? false,
          user: b.user,
          transactionId:b.transactionId,
          status : b.status

        })),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch analytics",
      error: error.message,
    });
  }
};

/* ───────────────────────── UPDATE BILL STATUS ───────────────────────── */
const updateBillStatus = async (req, res) => {
  const { billId, status, paymentMethod, mobile, transaction } = req.body; // added transaction
  console.log("Om Shahane ")
  console.log(req.body)
  try {
    const billToUpdate = await bill.findOne({ billId });
    if (!billToUpdate) {
      return res.status(404).json({ message: "Bill not found" });
    }

    billToUpdate.status = status;
    if (paymentMethod) billToUpdate.paymentMethod = paymentMethod;

    if (mobile) {
      billToUpdate.user = billToUpdate.user || {};
      billToUpdate.user.mobile = mobile;
      billToUpdate.markModified("user");
    }

    // Save the full payment/transaction response
    if (transaction) {
      billToUpdate.transactionId = transaction;
      billToUpdate.markModified("transactionId");
    }

    billToUpdate.updatedAt = new Date();
    await billToUpdate.save();

    const orderIds = billToUpdate.orders.map((o) => o.orderId).filter(Boolean);
    if (orderIds.length) {
      await Order.updateMany(
        { _id: { $in: orderIds } },
        { $set: { bill_status: "Paid" } },
      );
    }

    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to update bill status",
      error: error.message,
    });
  }
};

/* ───────────────────────── REPORT ───────────────────────── */
const generateReport = async (req, res) => {
  const { startDate, endDate, paymentMethod, mobile } = req.body;

  try {
    // Basic validation
    if (!startDate || !endDate) {
      return res.status(400).json({
        success: false,
        message: "startDate and endDate are required",
      });
    }

    // Prepare date range
    const start = new Date(startDate);
    start.setHours(0, 0, 0, 0);

    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    // Base query
    const query = {
      status: "Paid",
      updatedAt: { $gte: start, $lte: end },
    };

    // Payment method filter (case-insensitive exact match)
    if (paymentMethod && paymentMethod.trim()) {
      query.paymentMethod = {
        $regex: new RegExp(`^${paymentMethod.trim()}$`, "i"),
      };
    }

    // ────────────────────────────────────────────────
    // Mobile number filter – flexible matching
    // ────────────────────────────────────────────────
    if (mobile && mobile.trim()) {
      const cleanedMobile = mobile.trim().replace(/\D/g, ""); // remove everything except digits

      if (cleanedMobile.length >= 10) {
        // Try different common formats people might have saved:
        //   - plain 10 digits
        //   - +91 followed by 10 digits
        //   - last 10 digits (in case someone saved with country code or spaces)
        query["user.mobile"] = {
          $in: [
            cleanedMobile,
            `+91${cleanedMobile}`,
            cleanedMobile.slice(-10),
          ],
        };
      }
      // If less than 10 digits → we silently ignore (or you can return warning)
    }

    // Fetch matching bills
    const reports = await bill
      .find(query)
      .select(
        "billId table totalAmount status transactionId paymentMethod updatedAt user orders"
      )
      .lean(); // lean() = faster + plain JS objects

    // Calculate totals
    const total = reports.reduce((sum, bill) => sum + (bill.totalAmount || 0), 0);

    const cash = reports
      .filter((bill) => bill.paymentMethod?.toLowerCase() === "cash")
      .reduce((sum, bill) => sum + (bill.totalAmount || 0), 0);

    const online = total - cash;

    // Prepare response
    res.status(200).json({
      success: true,
      data: {
        total: Number(total.toFixed(2)),
        cash: Number(cash.toFixed(2)),
        online: Number(online.toFixed(2)),
        billCount: reports.length,
        filtersApplied: {
          dateRange: { start: start.toISOString(), end: end.toISOString() },
          paymentMethod: paymentMethod || "All",
          mobile: mobile || null,
        },
        bills: reports.map((b) => ({
          billId: b.billId,
          table: b.table,
          amount: b.totalAmount,
          paymentMethod: b.paymentMethod || "Unknown",
          date: b.updatedAt.toISOString(),
          mobile: b.user?.mobile || "N/A",
          orders: b.orders || [],
          user: b.user || null,
          transactionId: b.transactionId || null,
          status: b.status,
        })),
      },
    });
  } catch (error) {
    console.error("Generate report error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to generate report",
      error: error.message,
      // stack: process.env.NODE_ENV === "development" ? error.stack : undefined,
    });
  }
};

module.exports = {
  createBill,
  getAllBills,
  getAnalytics,
  updateBillStatus,
  generateReport,
};
