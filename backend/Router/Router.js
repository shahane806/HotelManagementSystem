const express = require("express");
const { loginController, registerController } = require("../Controllers/authController");
const { loginMiddlewere, registerMiddlewere, authenticate } = require("../Middlewere/authMiddlewere");
const { utilityController, utilityItemController, getNamedUtilities } = require("../Controllers/utilityController");
const router = express.Router();

router.get("/", (req, res) => {
  res.send("Hello World");
});

router.post("/auth/login",loginMiddlewere,loginController);
router.post("/auth/register",registerMiddlewere,registerController);
router.post("/utilities",authenticate,utilityController)
router.post("/utilities/:utilityName/items", authenticate, utilityItemController);
router.get("/utilities/:utilityName", authenticate,getNamedUtilities);
module.exports = router;
