const mongoose = require("mongoose")
const userSchema = new mongoose.Schema({
    username: {
        type: String,
        unique: true,
        required:true,
    },
    password:{
        type:String,
        required:true,
    },
    usertype:{
        type:String,
        required:true,
    },
    usersubtype:{
        type:String,
        required:true,
    },
    createTime: {
        type: Date,
        default: Date.now
    },
    updateTime:{
        type:Date,
        default:Date.now
    }
});
const userModel = mongoose.model('User', userSchema);
module.exports = userModel

