const mongoose = require("mongoose");

const routeSchema = new mongoose.Schema({
  donationId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: "Donation",
  },
  coordinates: [
    {
      lat: {
        type: Number,
        required: true,
      },
      lng: {
        type: Number,
        required: true,
      },
    },
  ],
});

module.exports = mongoose.model("Route", routeSchema);
