const mongoose = require("mongoose");
const dotenv = require("dotenv");

dotenv.config();

const mongoDbUrl = process.env.MONGODB_URL_AUTH;

const connectMongoAuth = async () => {
  try {
    await mongoose.connect(mongoDbUrl);
    console.log("MongoDbAuthCluster is connected");
  } catch (error) {
    console.error("MongoDB connection failed:", error.message);
    process.exit(1);
  }
};

module.exports = connectMongoAuth();
