const mongoose = require("mongoose");

async function connectDB() {
    try {
        await mongoose.connect("mongodb://localhost:27017/loginDB");
        console.log("MongoDB connected!");
    } catch (err) {
        console.error("DB connection error:", err);
    }
}

module.exports = connectDB;
