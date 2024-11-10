// components/Login.js
import axios from "axios";
import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { toast } from "sonner";

const Login = ({ setIsLoggedIn }) => {
  const navigate = useNavigate();
  const [isRegister, setIsRegister] = useState(false);

  const [email, setEmail] = useState("SOMETHING@email.com");
  const [password, setPassword] = useState("123456");
  const [confirmPassword, setConfirmPassword] = useState("123456");
  const [username, setUsername] = useState("harshith");

  const [address, setAddress] = useState("");

  const [latitude, setLatitude] = useState(null);
  const [longitude, setLongitude] = useState(null);
  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(success, error);
    } else {
      console.log("Geolocation not supported");
    }

    function success(position) {
      const latitude = position.coords.latitude;
      const longitude = position.coords.longitude;
      console.log(`Latitude: ${latitude}, Longitude: ${longitude}`);

      setLatitude(latitude);
      setLongitude(longitude);
    }

    function error() {
      console.log("Unable to retrieve your location");
    }
  }, []);
  // Empty dependency array ensures this runs only once on mount

  function success(position) {
    const latitude = position.coords.latitude;
    const longitude = position.coords.longitude;
    console.log(`Latitude: ${latitude}, Longitude: ${longitude}`);
    setLatitude(latitude);
    setLongitude(longitude);
  }

  function error() {
    console.log("Unable to retrieve your location");
  }

  const [errors, setErrors] = useState({
    email: "",
    password: "",
    confirmPassword: "",
    username: "",
  });

  const validateInputs = () => {
    let isValid = true;
    const newErrors = {
      email: "",
      password: "",
      confirmPassword: "",
      username: "",
    };

    // Email validation
    // if (!email) {
    //   newErrors.email = "Email is required";
    //   isValid = false;
    // } else if (!/\S+@\S+\.\S+/.test(email)) {
    //   newErrors.email = "Email is invalid";
    //   isValid = false;
    // }

    // Password validation
    if (!password) {
      newErrors.password = "Password is required";
      isValid = false;
    } else if (password.length < 6) {
      newErrors.password = "Password must be at least 6 characters";
      isValid = false;
    }

    // Additional validations for registration
    if (isRegister) {
      if (!username) {
        newErrors.username = "Shelter name is required";
        isValid = false;
      }

      if (password !== confirmPassword) {
        newErrors.confirmPassword = "Passwords do not match";
        isValid = false;
      }
    }

    setErrors(newErrors);
    return isValid;
  };

  const handleSubmit = async () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(success, error);
    } else {
      console.log("Geolocation not supported");
    }

    try {
      console.log(latitude);

      if (!latitude && !longitude) {
        toast("Please enable location permissions.");
        return;
      }
      const res = await axios.post(
        "https://3432-103-104-226-58.ngrok-free.app/api/registerNGO",
        {
          NGOemail: email,
          NGOname: username,
          NGOpassword: password,
          latitude,
          longitude,
          address: "saljjhasj",
        }
      );

      console.log("Response:", res.data);

      localStorage.setItem("ngoData", JSON.stringify(res.data));

      setIsLoggedIn(true); // Move inside try block

      navigate("/home"); // Uncomment when ready to navigate after login
    } catch (error) {
      console.log(error);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center px-4 bg-gray-50">
      <div className="w-full max-w-md space-y-8 bg-white p-8 rounded-lg shadow-lg">
        <div>
          <h2 className="text-center text-3xl font-bold tracking-tight text-gray-900">
            {isRegister ? "Register your shelter" : "Sign in to your account"}
          </h2>
        </div>

        <div className="mt-8 space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Shelter Name
            </label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2"
              placeholder="Enter shelter name"
            />
            {errors.username && (
              <p className="mt-1 text-sm text-red-600">{errors.username}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">
              Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2"
              placeholder="Enter your email"
            />
            {errors.email && (
              <p className="mt-1 text-sm text-red-600">{errors.email}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">
              Password
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2"
              placeholder="Enter your password"
            />
            {errors.password && (
              <p className="mt-1 text-sm text-red-600">{errors.password}</p>
            )}
          </div>

          {isRegister && (
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Confirm Password
              </label>
              <input
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2"
                placeholder="Confirm your password"
              />
              {errors.confirmPassword && (
                <p className="mt-1 text-sm text-red-600">
                  {errors.confirmPassword}
                </p>
              )}
            </div>
          )}

          {isRegister && (
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Add address{" "}
              </label>
              <input
                type="test"
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2"
                placeholder="Enter shelter address"
              />
              {errors.confirmPassword && (
                <p className="mt-1 text-sm text-red-600">
                  {errors.confirmPassword}
                </p>
              )}
            </div>
          )}

          <button
            onClick={handleSubmit}
            className="w-full rounded-md bg-blue-600 py-2 px-4 text-white hover:bg-blue-700"
          >
            {isRegister ? "Register" : "Sign In"}
          </button>
        </div>

        <p className="text-center text-sm text-gray-600">
          {isRegister ? "Already have an account? " : "Don't have an account? "}
          <button
            onClick={() => {
              setIsRegister(!isRegister);
              setEmail("");
              setPassword("");
              setConfirmPassword("");
              setUsername("");
              setErrors({
                email: "",
                password: "",
                confirmPassword: "",
                username: "",
              });
            }}
            className="text-blue-600 hover:text-blue-500"
          >
            {isRegister ? "Sign In" : "Register"}
          </button>
        </p>
      </div>
    </div>
  );
};

export default Login;
