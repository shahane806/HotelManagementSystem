const express = require("express");
const { loginController, registerController } = require("../Controllers/authController");
const { loginMiddlewere, registerMiddlewere } = require("../Middlewere/authMiddlewere");
const router = express.Router();

router.get("/", (req, res) => {
  res.send("Hello World");
});

router.post("/auth/login",loginMiddlewere,loginController);
router.post("/auth/register",registerMiddlewere,registerController);

module.exports = router;
