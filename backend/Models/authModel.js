const mongoose = require("mongoose")
const userSchema = new mongoose.Schema({
    username: {
        type: String,
        unique: true,
        require:true,
    },
    password:{
        type:String,
        require:true,
    },
    usertype:{
        type:String,
        require:true,
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

