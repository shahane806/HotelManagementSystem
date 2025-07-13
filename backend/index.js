const express = require("express")
const cors = require("cors")
const dotenv = require("dotenv")
const rateLimit = require("express-rate-limit")
const mongoose = require("mongoose")
const router = require("./Router/Router")
dotenv.config()

//om this is commit
const helmet = require("helmet")
const app = express()
app.use(helmet())
app.use(express.json())
app.use(cors())
app.use(express.urlencoded({
    extended:true,
    limit:"100kb"
}))
app.use(rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes 
    max: 100, // limit each IP to 100 requests per windowMs
    standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
    legacyHeaders: false, // Disable the `X-RateLimit-*` headers
}))
app.use(router)
const port = process.env.PORT || 5000
const mongoDbUrl = process.env.MONGODB_URL_AUTH 
app.listen(port,'0.0.0.0',()=>{
   console.log('App is running on port :'+port)
})
mongoose.connect(mongoDbUrl).then(()=>{
    console.log("MongoDbAuthCluster is connected")
})