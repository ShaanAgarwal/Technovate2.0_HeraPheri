const express = require("express");
// const bcrypt = require("bcrypt");
// const jwt = require("jsonwebtoken");
const { User, NGO } = require("../models/user.model.js"); // Assuming the User model is saved as User.js
const auth = require("../middlewares/verifytoken.js"); // Middleware for JWT verification

const router = express.Router();

// Register a new user
router.post("/register", async (req, res) => {
  try {
    const { username, password, email } = req.body;
    const user = new User({ username, password, email });
    console.log(user);

    await user.save();
    const token = user.generateAuthToken();
    return res.status(201).send({
      message: "User registered successfully!",
      access_token: token,
      username,
      email,
    });
  } catch (error) {
    return res.status(400).send(error);
  }
});

// Login route to authenticate user and return a JWT
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });

    if (!user || !(await user.isPasswordValid(password))) {
      return res.status(400).send({ error: "Invalid email or password" });
    }

    const token = user.generateAuthToken();

    return res.status(200).json({
      message: "Login successful",
      access_token: token,
      username: user.username, // Access the username from the user object
      email: user.email, // Access the email from the user object
    });
  } catch (error) {
    return res.status(500).send(error);
  }
});

// Add food item for authenticated user
router.post("/additem", auth, async (req, res) => {
  try {
    const { name, expiry_date, quantity, unit } = req.body;
    const user = await User.findById(req.user.id);
    console.log(req.body);

    user.foodItems.push({ name, expiry_date, quantity, unit });
    await user.save();

    res.status(201).send({
      message: "Food item added successfully!",
      name,
      expiry_date,
      dateAdded: user.dateAdded,
      quantity,
      unit: user.unit,
    });
  } catch (error) {
    res.status(500).send(error);
  }
});

router.get("/getitems", auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (user) {
      return res.json({ foodItems: user.foodItems });
    }

    return res.status(404).json({
      message: "User not found",
    });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

router.post("/userDonationData", auth, async (req, res) => {
  try {
    const { foodName, servingSize, location } = req.body;

    // Parse latitude and longitude from location
    const lat = parseFloat(location.split(", ")[0].split(": ")[1]);
    const long = parseFloat(location.split(", ")[1].split(": ")[1]);
    if (isNaN(lat) || isNaN(long)) {
      return res.status(400).send({ error: "Invalid location coordinates" });
    }

    const user = await User.findById(req.user.id);

    // Add the donation to the user's record
    user.foodDonation.push({
      foodName,
      location: {
        type: "Point",
        coordinates: [long, lat],
      },
      servingSize,
    });
    await user.save();

    // Fetch all NGOs and filter by distance
    const ngos = await NGO.find();
    const nearbyNGOs = [];
    const MAX_DISTANCE_KM = 5;

    // Haversine formula to calculate distance between two coordinates
    function haversineDistance(lat1, lon1, lat2, lon2) {
      const toRad = (value) => (value * Math.PI) / 180;

      const R = 6371; // Radius of Earth in km
      const dLat = toRad(lat2 - lat1);
      const dLon = toRad(lon2 - lon1);
      const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRad(lat1)) *
          Math.cos(toRad(lat2)) *
          Math.sin(dLon / 2) *
          Math.sin(dLon / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      return R * c;
    }

    // Find NGOs within the specified distance
    for (const ngo of ngos) {
      const ngoLat = ngo.location.coordinates[1];
      const ngoLong = ngo.location.coordinates[0];

      const distance = haversineDistance(lat, long, ngoLat, ngoLong);
      if (distance <= MAX_DISTANCE_KM) {
        nearbyNGOs.push(ngo);
      }
    }

    // Notify each nearby NGO (for debugging)
    let cnt = 0;
    for (const ngo of nearbyNGOs) {
      cnt++;
      console.log(`Notified NGO ${cnt}:`, ngo.NGOname);
      ngo.pickupReq.push({
        foodName,
        pickupLocation: {
          type: "Point",
          coordinates: [long, lat],
        },
        servingSize,
      });
      await ngo.save();
    }

    return res.status(201).json({
      message: "Donation created and nearby NGOs notified",
      foodName,
      location: { lat, long },
      servingSize,
      nearbyNGOs,
    });
  } catch (error) {
    console.error("Error in donation route:", error);
    return res.status(500).send({ error: error.message });
  }
});

router.get("/getdonationtrackingdata", auth, async (req, res) => {
  try {
    const id = req.user.id;

    // Find NGO by ID
    const user = await User.findById(id);
    if (!user) {
      return res.status(404).send({ message: "User not found" });
    }

    // Generate token
    console.log(user.foodDonation);
    return res.status(200).send({
      message: "User data retrieved successfully!",
      pickupReq: user.foodDonation,
    });
  } catch (error) {
    return res.status(500).send({ error: error.message });
  }
});
router.delete("/deleteitem", auth, async (req, res) => {
  const userId = req.user.id;
  console.log(userId);
  const { itemId } = req.body;
  console.log(itemId);

  try {
    // Find the user and remove the specified food item from foodItems array
    const user = await User.findByIdAndUpdate(
      userId,
      { $pull: { foodItems: { _id: itemId } } },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    res.status(200).json({
      message: "Food item removed successfully",
      user,
    });
  } catch (error) {
    res
      .status(500)
      .json({ error: "An error occurred while removing the food item" });
  }
});

// router.post("/findNearbyNGOs", auth, async (req, res) => {
//   try {
//     const { latitude, longitude, maxDistance = 5000 } = req.body; // maxDistance is in meters (default 5 km)

//     // Ensure latitude and longitude are provided
//     if (!latitude || !longitude) {
//       return res
//         .status(400)
//         .json({ error: "Latitude and longitude are required." });
//     }

//     // Find nearby NGOs
//     const nearbyNGOs = await NGO.find({
//       location: {
//         $near: {
//           $geometry: { type: "Point", coordinates: [longitude, latitude] },
//           $maxDistance: maxDistance,
//         },
//       },
//     });

//     if (nearbyNGOs.length === 0) {
//       return res.status(404).json({ message: "No nearby NGOs found" });
//     }

//     return res.status(200).json({ nearbyNGOs });
//   } catch (error) {
//     return res.status(500).send({ error: error.message });
//   }
// });

module.exports = router;
