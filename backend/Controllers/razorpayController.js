const createOrder = async (req, res) => {
  const Razorpay = require("razorpay");
  const razorpay = new Razorpay({
    key_id: "rzp_test_RfabomUGyoEZ3w",
    key_secret: "N046SlKSfFpOtu9VzOnYVT4G",
  });
  try {
    const { amount, currency = "INR", receipt } = req.body;
    const order = await razorpay.orders.create({ amount, currency, receipt });
    res.json(order);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

module.exports = {
  createOrder,
};
