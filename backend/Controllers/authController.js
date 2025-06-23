const jwt = require("jsonwebtoken");
const bcryptJs = require("bcryptjs");
const usermodel = require("../Models/authModel");
const loginController = async (req, res) => {
  const { username, password, usertype } = req?.body;
  const user = await usermodel.findOne({
    username: username,
  });
  if (!user) {
    return res.status(201).send({
      message: "Username or Password is incorrect try again",
    });
  }
  let comparePassword = bcryptJs.compare(password, user?.password);
  let hashpassword = user?.password
  if (comparePassword) {
    jwt.sign(
      { username,hashpassword, usertype },
      process.env.SECRET_KEY,
      { expiresIn: 3600 },
      (err, token) => {
        if (err) {
          return res.status(500).json({ message: "Error generating token" });
        } else {
          return res.status(200).send({ token: token });
        }
      }
    );
  } else {
    return res?.status(201).send({
      message: "Username or Password is incorrect try again",
    });
  }
};
const registerController = async (req, res) => {
  const { username, password, usertype } = req?.body;
  const hashpassword = await bcryptJs.hash(password, 3);
  const user = await usermodel.findOne({ username: username });
  console.log(user);
  if (user) {
    return res.status(401).send({
      message: "user already registered by this username use another username",
    });
  }
  await usermodel({
    username: username,
    password: hashpassword,
    usertype: usertype,
  }).save();
  jwt.sign(
    { username, hashpassword, usertype },
    process.env.SECRET_KEY,
    { expiresIn: 3600 },
    (err, token) => {
      if (err) {
        return res.status(500).json({ message: "Error generating token" });
      } else {
        return res.status(200).send({ token: token });
      }
    }
  );
};
module.exports = { loginController, registerController };
