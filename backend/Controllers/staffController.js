const Staff = require("../Models/staffModel");
const bcrypt = require("bcryptjs");
const { v4: uuidv4 } = require("uuid");
const getAllStaff = async (req, res) => {
  try {
    const staff = await Staff.find();
    console.log(staff)
    res.status(200).json(staff);
  } catch (error) {
    res.status(500).json({ message: "Error fetching staff", error });
  }
};

const createStaff = async (req, res) => {
  try {
    const { fullName, email, mobile, aadhaarNumber, role, password } = req.body;

    if (!fullName || !email || !mobile || !aadhaarNumber) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const staff = new Staff({
      userId: uuidv4(), // auto-generate
      fullName,
      email,
      mobile,
      aadhaarNumber,
      role,
      password: password ? await bcrypt.hash(password, 12) : undefined,
    });

    await staff.save();
    const { password: pwd, ...staffObj } = staff.toObject();
    res.status(201).json(staffObj);
  } catch (error) {
    console.error("Staff creation error:", error);
    res.status(400).json({ message: "Error creating staff", error });
  }
};
const updateStaff = async (req, res) => {
  console.log("update request params:", req.params);

  try {
    const staff = await Staff.findOneAndUpdate(
      { userId: req.params.userId },
      req.body,
      { new: true }
    );
    if (!staff) {
      return res.status(404).json({ message: "Staff not found" });
    }
    res.status(200).json(staff);
  } catch (error) {
    res.status(500).json({ message: "Error updating staff", error });
  }
};

const deleteStaff = async (req, res) => {
  console.log("Delete request params:", req.params);

  try {
    let staff = await Staff.findOneAndDelete({ userId: req.params.userId });

    if (!staff) {
      staff = await Staff.findByIdAndDelete(req.params.userId);
    }

    if (!staff) {
      return res.status(404).json({ message: "Staff not found" });
    }

    res.status(200).json({ message: "Staff deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: "Error deleting staff", error });
  }
};

module.exports = { createStaff, getAllStaff, updateStaff, deleteStaff };
