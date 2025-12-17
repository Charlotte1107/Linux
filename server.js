const express = require("express");
const { exec } = require("child_process");
const mongoose = require("mongoose");
const bcrypt = require("bcrypt");
const bannedIPs = new Set();
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
  username: { type: String, unique: true },
  password: String,
  createdAt: { type: Date, default: Date.now }
});

const User = mongoose.model("User", userSchema);

/* =====================
   Login Security Settings
===================== */
const FAIL_LIMIT = 3;
const failMap = {}; // { ip: count }

function banIP(ip) {
  console.log(`Blocking IP via UFW: ${ip}`);
  bannedIPs.add(ip); 
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

  const ip =
    req.headers["x-forwarded-for"] ||
    req.socket.remoteAddress.replace("::ffff:", "");

  if (bannedIPs.has(ip)) {
    return res.json({ message: "IP is blocked" });
  }
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
   const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new User({
      username,
      password:hashedPassword, 
    });

    await newUser.save();

    console.log(`REGISTER SUCCESS - USER: ${username}`);
    res.json({ message: "Register successful" });
  } catch (err) {
    console.error("Register error:", err);
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
   if (bannedIPs.has(ip)) return res.status(403).json({ message: "IP is blocked" });
  try {
    // 查 MongoDB 使用者
    const user = await User.findOne({ username });

    if (!user) {
  failMap[ip] = (failMap[ip] || 0) + 1;
  console.log(`LOGIN FAIL from ${ip} (${failMap[ip]} times)`);
 if (failMap[ip] >= FAIL_LIMIT) {
    banIP(ip);
    return res.json({ message: "IP banned due to multiple failures" });
  } 
 return res.json({ message: "Login failed" });
} 


    // 對加密密碼
const isMatch = await bcrypt.compare(password, user.password);

if (!isMatch) {
  failMap[ip] = (failMap[ip] || 0) + 1;
  console.log(`LOGIN FAIL from ${ip} (${failMap[ip]} times)`);

  if (failMap[ip] >= FAIL_LIMIT) {
    banIP(ip);
    return res.json({ message: "IP banned due to multiple failures" });
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
app.listen(3000,"0.0.0.0", () => {
  console.log("Server running on port 3000");
});


