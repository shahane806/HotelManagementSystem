const express = require("express");
const { loginController , forgotPasswordController, resetPasswordController } = require("../Controllers/authController");
const {  authenticate } = require("../Middlewere/authMiddlewere");
const { utilityController, utilityItemController, getNamedUtilities, deleteUtilityItemController } = require("../Controllers/utilityController");
const { addMenuItemController, deleteMenuItemController } = require("../Controllers/utilityController");
const { createBill, getAllBills, updateBillStatus } = require("../Controllers/billController");
const { getAllCustomers, createCustomer, deleteCustomer, updateCustomer } = require("../Controllers/customerController");
const { createOrder } = require("../Controllers/razorpayController");
const { getAllStaff, createStaff, deleteStaff, updateStaff } = require("../Controllers/staffController");
const path = require('path');   // ← ADD THIS LINE
const router = express.Router();
router.get("/", (req, res) => {
  res.send("Hello World");
});

router.get("/reset-password/:token", (req, res, next) => {
  if (req.params.token.includes(".")) return next();
  res.sendFile(path.join(__dirname, "../public/reset-password.html"));
});

router.post('/api/auth/reset-password/:token', resetPasswordController);
router.post("/auth/login", loginController);
router.post("/auth/forgot-password", forgotPasswordController);
///#Create New Utility  
///Dont hit this api until you create all the code regarding that utility in the frontend 
///line Models, Service, Bloc etc.
router.post("/utilities",authenticate,utilityController)
///Insert New Item in the Utility
router.post("/utilities/:utilityName/items", authenticate, utilityItemController);
///Get all Utility
router.get("/utilities/:utilityName",authenticate,getNamedUtilities);
///#Delete Menu Utility Menus
router.delete("/utilities/:utilityName/items/:itemName", authenticate, deleteUtilityItemController);
///#Delete Other Utility Items 
router.delete("/utilities/:utilityName/:itemName", authenticate, deleteUtilityItemController);
///#Inserting New Item in Menu to Menu Utility
router.post("/utilities/:utilityName/:menuName/items", authenticate, addMenuItemController);
///#Delete Item from Menu from Menu Utiltiy
router.delete("/utilities/:utilityName/:menuName/items/:menuitemname", authenticate, deleteMenuItemController);

router.post('/payTableBill', authenticate, createBill);
router.get('/getAllBills',authenticate,getAllBills)
router.post('/updateBillStatus', authenticate, updateBillStatus);
router.get('/customers/', authenticate,getAllCustomers);
router.post('/customers/', authenticate,createCustomer);
router.delete('/customers/:userId',authenticate, deleteCustomer);
router.put('/customers/:userId',authenticate, updateCustomer);
router.post('/create-razorpay-order',authenticate, createOrder);
router.get('/staff/',authenticate,getAllStaff);
router.post('/staff',authenticate,createStaff);
router.delete('/staff/:userId',authenticate, deleteStaff);
router.put('/staff/:userId',authenticate, updateStaff);





module.exports = router;