const express = require("express");
const app = express();
const connectDB = require("./db");
const authRoutes = require("./routes/auth");

connectDB();
app.use(express.json());
app.use("/api/auth", authRoutes);

app.listen(3000, () => console.log("Server running on port 3000"));
