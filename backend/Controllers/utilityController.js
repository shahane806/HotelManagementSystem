const UtilityModel = require("../Models/utilitiesModel")
const utilityController = async(req,res)=>{
try {
    const { utilityName } = req.body;
    const utility = new UtilityModel({ utilityName, utilityItems: [] });
    await utility.save();
    res.status(201).json(utility);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
}

const utilityItemController = async (req, res) => {
  try {
    // if (req.user.usertype !== "Admin" && req.user.usertype !== "Manager") {
    //   return res.status(403).json({ error: "Unauthorized" });
    // }
    const { utilityName } = req.params;
    const item = req.body;
    const utility = await UtilityModel.findOne({ utilityName });
    if (!utility) {
      return res.status(404).json({ error: "Utility not found" });
    }
    utility.utilityItems.push(item);
    await utility.save();
    res.status(200).json(utility);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
}
const getAllUtilities =  async (req, res) => {
  try {
    const utilities = await UtilityModel.find();
    res.status(200).json(utilities);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}
module.exports = {utilityController,utilityItemController,getAllUtilities}