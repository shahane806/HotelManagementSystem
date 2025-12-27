const cloudinary = require('cloudinary').v2
// const {cloudinary }  = require('cloudinary');
const { CloudinaryStorage } = require("multer-storage-cloudinary");
const multer = require("multer");
const dotenv = require("dotenv");

dotenv.config();

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: "HMS/room-images",
    allowed_formats: ["jpg", "jpeg", "png"],
    public_id: (req, file) => {
      const name = file.originalname.split(".")[0].replace(/\s+/g, "-");
      return `${Date.now()}-${name}`;
    },
  },
});

const upload = multer({ storage: storage });

module.exports = { upload };
