const mongoose = require("mongoose");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const userDonationData = new mongoose.Schema({
  foodName: {
    type: String,
    // required: true,
  },
  servingSize: {
    type: String,
    // required: true,
  },
  location: {
    type: { type: String, default: "Point" },
    coordinates: { type: [Number], index: "2dsphere" }, // [longitude, latitude]
  },
});

const foodItemSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  quantity: {
    type: Number,
    required: true,
  },
  unit: {
    type: String,
    enum: ["Units", "kg"],
    required: true,
  },
  expiry_date: {
    type: String,
  },
  dateAdded: {
    type: String,
    default: Date.now,
  },
});

const userSchema = new mongoose.Schema(
  {
    username: {
      type: String,
      required: true,
    },
    password: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
    },
    foodItems: [foodItemSchema],
    foodDonation: [userDonationData],
  },
  { timestamps: true }
);

const ngoSchema = new mongoose.Schema(
  {
    NGOname: {
      type: String,
      required: true,
    },
    NGOpassword: {
      type: String,
      required: true,
    },
    NGOemail: {
      type: String,
      required: true,
      unique: true,
    },
    address: {
      type: String,
    },
    location: {
      type: { type: String, default: "Point" },
      coordinates: { type: [Number], index: "2dsphere" }, // [longitude, latitude]
    },
    pickupReq: [
      {
        type: {
          pickupLocation: {
            type: { type: String, default: "Point" },
            coordinates: { type: [Number], index: "2dsphere" }, // [longitude, latitude]
          },
          foodName: {
            type: String,
          },
          servingSize: {
            type: Number,
          },
        },
      },
    ],
  },
  { timestamps: true }
);

// Hash the password before saving
userSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

ngoSchema.pre("save", async function (next) {
  if (!this.isModified("NGOpassword")) return next();
  this.NGOpassword = await bcrypt.hash(this.NGOpassword, 10);
  next();
});

// Generate JWT Token
userSchema.methods.generateAuthToken = function () {
  const token = jwt.sign({ id: this._id }, process.env.JWT_SECRET, {
    expiresIn: "1h",
  });
  return token;
};
ngoSchema.methods.generateAuthToken = function () {
  const token = jwt.sign({ id: this._id }, process.env.JWT_SECRET, {
    expiresIn: "1h",
  });
  return token;
};

// Check password validity
userSchema.methods.isPasswordValid = async function (password) {
  return await bcrypt.compare(password, this.password);
};
ngoSchema.methods.isPasswordValid = async function (password) {
  return await bcrypt.compare(password, this.password);
};

const User = mongoose.model("User", userSchema);
const NGO = mongoose.model("NGO", ngoSchema);

module.exports = { User, NGO };
