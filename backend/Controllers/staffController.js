const Staff = require('../Models/staffModel');

 const getAllStaff = async (req, res) => {
  try {
    const staff = await Staff.find();
    res.status(200).json(staff);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching staff', error });
  }
};

 const createStaff = async (req, res) => {
  console.log(req.body)
  try {
    const staff = new Staff(req.body);
    await staff.save();
    res.status(201).json(staff);
  } catch (error) {
    res.status(400).json({ message: 'Error creating staff', error });
  }
};

const updateStaff = async (req, res) => {
    console.log("update request params:", req.params);

  try {
    const staff = await Staff.findOneAndUpdate({ userId: req.params.userId }, req.body, { new: true });
    if (!staff) {
      return res.status(404).json({ message: 'Staff not found' });
    }
    res.status(200).json(staff);
  } catch (error) {
    res.status(500).json({ message: 'Error updating staff', error });
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
      return res.status(404).json({ message: 'Staff not found' });
    }

    res.status(200).json({ message: 'Staff deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting staff', error });
  }
};


module.exports = {createStaff,getAllStaff,updateStaff,deleteStaff}