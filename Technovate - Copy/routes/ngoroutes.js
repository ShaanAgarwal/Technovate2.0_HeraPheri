const express = require("express");
const { NGO } = require("../models/user.model.js");
const auth = require("../middlewares/verifytoken.js");
const routeModel = require("../models/route.model.js");
const router = express.Router();

// Register a new NGO
router.post("/registerNGO", async (req, res) => {
  try {
    const { NGOname, NGOpassword, NGOemail, latitude, longitude } = req.body;
    // console.log(latitude);

    // Create new NGO with geolocation data
    const ngo = new NGO({
      NGOname,
      NGOpassword,
      NGOemail,
      location: {
        type: "Point",
        coordinates: [longitude, latitude],
      },
    });
    await ngo.save();

    // Generate token after saving the NGO
    const token = ngo.generateAuthToken();
    return res.status(201).send({
      message: "NGO registered successfully!",
      access_token: token,
      ngoname: ngo.NGOname,
      email: ngo.NGOemail,
      location: ngo.location.coordinates,
      id: ngo.id,
    });
  } catch (error) {
    return res.status(400).send({ error: error.message });
  }
});

router.post("/send-path", async (req, res) => {
  try {
    const { donationId, coordinates } = req.body;
    console.log(req.body.donationId);

    if (
      !donationId ||
      !Array.isArray(coordinates) ||
      coordinates.length === 0
    ) {
      return res.status(400).json({
        message: "Donation ID and coordinates are required",
        success: false,
      });
    }

    const newRoute = new routeModel({ donationId, coordinates });

    await newRoute.save();

    return res.status(201).json({
      message: "Route coordinates saved successfully",
      success: true,
      route: newRoute,
    });
  } catch (error) {
    console.error(error);
    return res
      .status(500)
      .json({ message: "Internal Server Error", success: false });
  }
});

router.get("/getDonationIds", async (req, res) => {
  try {
    // Find all unique donation IDs from the Route collection
    const donationIds = await routeModel.find().distinct("donationId");

    return res.status(200).json({
      message: "Donation IDs fetched successfully",
      success: true,
      donationIds,
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      message: "Internal Server Error",
      success: false,
    });
  }
});

router.post("/getCoordinates", async (req, res) => {
  try {
    const { donationId } = req.body;

    // Validate that donationId is provided
    if (!donationId) {
      return res.status(400).json({
        message: "Donation ID is required",
        success: false,
      });
    }

    // Find the route document with the specified donationId
    const route = await routeModel.findOne({ donationId });

    // Check if a route with the given donationId exists
    if (!route) {
      return res.status(404).json({
        message: "Route not found for the specified Donation ID",
        success: false,
      });
    }

    return res.status(200).json({
      message: "Coordinates fetched successfully",
      success: true,
      coordinates: route.coordinates,
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      message: "Internal Server Error",
      success: false,
    });
  }
});

router.post("/getPickupData", auth, async (req, res) => {
  try {
    const id = req.user.id;
    console.log(id);
    console.log("NGO ID:", id);

    // Find NGO by ID
    const ngo = await NGO.findById(id);
    if (!ngo) {
      return res.status(404).send({ message: "NGO not found" });
    }

    // Generate token

    return res.status(200).send({
      message: "NGO data retrieved successfully!",
      pickupReq: ngo.pickupReq,
    });
  } catch (error) {
    return res.status(500).send({ error: error.message });
  }
});

// Login route for NGO (auth middleware removed here)
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const ngo = await NGO.findOne({ email });

    if (!ngo || !(await ngo.isPasswordValid(password))) {
      return res.status(400).send({ error: "Invalid email or password" });
    }

    const token = ngo.generateAuthToken();
    return res.status(200).json({
      message: "Login successful",
      access_token: token,
      ngoname: ngo.ngoname,
      email: ngo.email,
    });
  } catch (error) {
    return res.status(500).send({ error: error.message });
  }
});
router.delete("/cancelPickup", auth, async (req, res) => {
  const ngoId = req.user.id;
  console.log(ngoId);
  const { pickupId } = req.body;
  console.log(pickupId);

  try {
    // Find the user and remove the specified food item from foodItems array
    const ngo = await NGO.findByIdAndUpdate(
      userId,
      { $pull: { pickupReq: { _id: pickupId } } },
      { new: true }
    );

    if (!ngo) {
      return res.status(404).json({ error: "NGO not found" });
    }

    res.status(200).json({
      message: "Cancelled order successfully",
      user,
    });
  } catch (error) {
    res
      .status(500)
      .json({ error: "An error occurred while removing the order" });
  }
});

module.exports = router;
