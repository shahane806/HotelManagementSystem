require("dotenv").config();
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const Staff = require("../Models/staffModel");
const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 465,
  secure: true,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

const JWT_SECRET = process.env.SECRET_KEY;
const JWT_EXPIRES_IN = "7d";

// ===== LOGIN =====
const loginController = async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ success: false, message: "Username and password are required" });
    }

    const user = await Staff.findOne({ email: username.trim().toLowerCase() }).select("+password");

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ success: false, message: "Invalid credentials" });
    }

    const token = jwt.sign(
      {
        userId: user._id,
        username: user.fullName,
        role: user.role,
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    return res.status(200).json({
      success: true,
      message: "Login successful",
      token,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    console.error("Login Error:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

// ===== FORGOT PASSWORD =====
const forgotPasswordController = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ success: false, message: "Email is required" });

    const user = await Staff.findOne({ email: email.trim().toLowerCase() });
    if (user) {
      const resetToken = crypto.randomBytes(32).toString("hex");
      const hashedToken = crypto.createHash("sha256").update(resetToken).digest("hex");

      user.resetPasswordToken = hashedToken;
      user.resetPasswordExpires = Date.now() + 15 * 60 * 1000; // 15 minutes
      await user.save({ validateBeforeSave: false });

      const resetUrl = `${process.env.FRONTEND_URL}/reset-password/${resetToken}`;

        // Beautiful, responsive HTML email
        const html = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Reset Your Hotel Pro Password</title>
        </head>
        <body style="margin:0; padding:0; background:#f4f4f4; font-family:Arial, sans-serif;">
          <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f4; padding:40px 20px;">
            <tr>
              <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background:white; border-radius:12px; overflow:hidden; box-shadow:0 10px 30px rgba(0,0,0,0.1);">
                  <tr>
                    <td style="background:#667eea; color:white; padding:30px; text-align:center;">
                      <h1 style="margin:0; font-size:28px;">Hotel Pro</h1>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding:40px 30px; line-height:1.6; color:#333;">
                      <h2 style="color:#667eea;">Password Reset Request</h2>
                      <p>Hello <strong>${user.fullName}</strong>,</p>
                      <p>We received a request to reset your password. Click the button below to set a new one:</p>
                      
                      <div style="text-align:center; margin:35px 0;">
                        <a href="${resetUrl}" 
                           style="background:#667eea; color:white; padding:16px 36px; text-decoration:none; border-radius:50px; font-weight:bold; font-size:16px; display:inline-block;">
                          Reset My Password
                        </a>
                      </div>
                      
                      <p style="color:#666; font-size:14px;">
                        This link will expire in <strong>15 minutes</strong> for security.<br>
                        If you didn't request this, please ignore this email — your password will remain unchanged.
                      </p>
                    </td>
                  </tr>
                  <tr>
                    <td style="background:#f8f9fa; padding:20px; text-align:center; color:#888; font-size:12px;">
                      © 2025 Hotel Pro. All rights reserved.<br>
                      If you're having trouble clicking the button, copy and paste this link:<br>
                      <span style="color:#667eea; word-break:break-all;">${resetUrl}</span>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        </body>
        </html>`;

      await transporter.sendMail({
        from: `"Hotel Pro" <${process.env.EMAIL_USER}>`,
        to: user.email,
        subject: "Password Reset - Hotel Pro",
        html,
      });
    }

    return res.status(200).json({ success: true, message: "If an account exists, a reset link has been sent" });
  } catch (error) {
    console.error("Forgot Password Error:", error);
    return res.status(500).json({ success: false, message: "Server error "+error });
  }
};

// ===== RESET PASSWORD =====
const resetPasswordController = async (req, res) => {
  try {
    const { token } = req.params;
    const { password, confirmPassword } = req.body;

    if (!password || password.length < 8) return res.status(400).json({ success: false, message: "Password must be at least 8 characters" });
    if (password !== confirmPassword) return res.status(400).json({ success: false, message: "Passwords do not match" });

    const hashedToken = crypto.createHash("sha256").update(token).digest("hex");

    const user = await Staff.findOne({ resetPasswordToken: hashedToken, resetPasswordExpires: { $gt: Date.now() } });
    if (!user) return res.status(400).json({ success: false, message: "Token invalid or expired" });

    user.password = await bcrypt.hash(password, 12);
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();

    return res.status(200).json({ success: true, message: "Password reset successful" });
  } catch (error) {
    console.error("Reset Password Error:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

module.exports = { loginController, forgotPasswordController, resetPasswordController };
