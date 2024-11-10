const jwt = require("jsonwebtoken");
const { User, NGO } = require("../models/user.model.js");

const auth = async (req, res, next) => {
  try {
    const token = req.header("Authorization").replace("Bearer ", "");
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Find user or NGO based on decoded token ID
    const user = await User.findById(decoded.id);
    const ngo = await NGO.findById(decoded.id);

    if (!user && !ngo) {
      throw new Error("Authentication failed");
    }

    // Attach user or NGO to the request
    req.user = user || ngo;
    next();
  } catch (error) {
    res.status(401).send({ error: "Please authenticate" });
  }
};

module.exports = auth;
