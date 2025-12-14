const express = require("express");
const fs = require("fs");
const { exec } = require("child_process");
const mongoose = require("mongoose");

const app = express();
app.use(express.json());

/* =====================
   MongoDB Connection
===================== */
mongoose
  .connect("mongodb://127.0.0.1:27017/loginDB")
  .then(() => console.log("MongoDB connected!"))
  .catch((err) => console.error("MongoDB connection error:", err));

/* =====================
   User Model
===================== */
const userSchema = new mongoose.Schema({
  username: String,
  password: String,
});

const User = mongoose.model("User", userSchema);

/* =====================
   Login Security Settings
===================== */
const FAIL_LIMIT = 3;
const failMap = {}; // { ip: count }

function banIP(ip) {
  console.log(`Blocking IP via UFW: ${ip}`);
  exec(`sudo ufw deny from ${ip}`, (err) => {
    if (err) {
      console.error("UFW error:", err.message);
    }
  });
}

/* =====================
   Register API
===================== */
app.post("/register", async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.json({ message: "Username and password required" });
  }

  try {
    // 檢查帳號是否已存在
    const existUser = await User.findOne({ username });
    if (existUser) {
      return res.json({ message: "Username already exists" });
    }

    // 建立新使用者
    const newUser = new User({
      username,
      password, // 目前先用明碼（之後可加 bcrypt）
    });

    await newUser.save();

    console.log(`REGISTER SUCCESS - USER: ${username}`);
    res.json({ message: "Register successful" });
  } catch (err) {
    console.error("Register error:", err);
    res涉及
    res.status(500).json({ message: "Server error" });
  }
});

/* =====================
   Login API
===================== */
app.post("/login", async (req, res) => {
  const { username, password } = req.body;

  const ip =
    req.headers["x-forwarded-for"] ||
    req.socket.remoteAddress.replace("::ffff:", "");

  try {
    // 🔑 查 MongoDB 使用者
    const user = await User.findOne({ username });

    // ❌ 帳號不存在 or 密碼錯誤
    if (!user || user.password !== password) {
      failMap[ip] = (failMap[ip] || 0) + 1;
      console.log(`LOGIN FAIL from ${ip} (${failMap[ip]} times)`);

      if (failMap[ip] >= FAIL_LIMIT) {
        banIP(ip);
        return res.json({
          message: "IP banned due to multiple failures",
        });
      }

      return res.json({ message: "Login failed" });
    }

    // ✅ 登入成功
    delete failMap[ip];
    console.log(`LOGIN SUCCESS from ${ip}`);

    res.json({ message: "Login successful" });
  } catch (err) {
    console.error("Server error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

/* =====================
   Start Server
===================== */
app.listen(3000, () => {
  console.log("Server running on port 3000");
});

