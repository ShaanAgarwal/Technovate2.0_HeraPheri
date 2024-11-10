const express = require("express");
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const cors = require("cors");
const bodyParser = require("body-parser");
const userRoutes = require("./routes/useroutes.js"); // Import routes
const ngoRoutes = require("./routes/ngoroutes.js"); // Import routes

dotenv.config(); // Load environment variables from .env file

const app = express();
const port = process.env.PORT || 5000;

// Middleware
app.use(cors()); // To allow cross-origin requests
app.use(bodyParser.json()); // Parse JSON bodies

// MongoDB Connection
mongoose
  .connect(process.env.MONGO_DB_URL, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("Connected to MongoDB"))
  .catch((error) => console.error("MongoDB connection error:", error));

// Routes
app.use("/api", userRoutes); // API routes for user registration, login, and food item addition
app.use("/api", ngoRoutes); // API routes for user registration, login, and food item addition

// Default Route
app.get("/", (req, res) => {
  res.send("Welcome to the Food Tracker API");
});

// Start the Server
app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
