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
const getNamedUtilities =  async (req, res) => {
  console.log("HIT")
  const {utilityName} = req?.params;
  try {
    const utilities = await UtilityModel.find({utilityName: utilityName});
    res.status(200).json(utilities);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}
const deleteUtilityItemController = async (req, res) => {
  try {
    const { utilityName, itemName } = req.params;
    console.log(utilityName,itemName);
    const utility = await UtilityModel.findOne({ utilityName });

    if (!utility) {
      return res.status(404).json({ error: "Utility not found" });
    }

    utility.utilityItems = utility.utilityItems.filter(
      (item) => 
        item.name != itemName
    );
    await utility.save();

    res.status(200).json({ message: "Item deleted", utility });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const addMenuItemController = async (req, res) => {
  const { utilityName, menuName } = req.params;
  const { menuitemname, price } = req.body;

  try {
    const updated = await UtilityModel.findOneAndUpdate(
      { utilityName, "utilityItems.name": menuName },
      {
        $push: {
          "utilityItems.$.items": { menuitemname, price }
        }
      },
      { new: true }
    );

    if (!updated) return res.status(404).json({ message: "Menu not found" });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

const deleteMenuItemController = async (req, res) => {
  const { utilityName, menuName, menuitemname } = req.params;

  try {
    const updated = await UtilityModel.findOneAndUpdate(
      { utilityName, "utilityItems.name": menuName },
      {
        $pull: {
          "utilityItems.$.items": { menuitemname }
        }
      },
      { new: true }
    );

    if (!updated) return res.status(404).json({ message: "Menu or item not found" });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

module.exports = {utilityController,utilityItemController,getNamedUtilities,deleteUtilityItemController,addMenuItemController,deleteMenuItemController}