const express = require("express");
const router = express.Router();
const {upload}=require('../config/cloudinary-multer')
const {createRoom} =require('../Controllers/roomController')

// Create room with multiple images
router.post('/', upload.array('images', 5), createRoom);

module.exports = router;
