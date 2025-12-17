const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const User = require("../models/User");

// 註冊
router.post("/register", async (req, res) => {
    const { username, password } = req.body;

    try {
        const exists = await User.findOne({ username });
        if (exists) return res.status(400).json({ message: "Username already exists" });

        const hash = await bcrypt.hash(password, 10);
        await User.create({ username, password: hash });

        res.json({ message: "Registered successfully" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 登入
router.post("/login", async (req, res) => {
    const { username, password } = req.body;

    try {
        const user = await User.findOne({ username });
        if (!user) return res.status(400).json({ message: "Login failed" });

        const valid = await bcrypt.compare(password, user.password);
        if (!valid) return res.status(400).json({ message: "Login failed" });

        res.json({ message: "Login successful" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
