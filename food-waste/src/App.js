// App.js
import React, { useEffect, useState } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Login from "./pages/Login";
import Home from "./pages/Home";
import FoodPickup from "./pages/FoodPickup";

const App = () => {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  // Check localStorage for ngoData on component mount
  useEffect(() => {
    const ngoData = localStorage.getItem("ngoData");
    if (ngoData) {
      setIsLoggedIn(true); // Set logged-in status to true if ngoData exists
    }
  }, []);

  return (
    <BrowserRouter>
      <Routes>
        <Route
          path="/login"
          element={
            isLoggedIn ? (
              <Navigate to="/home" replace />
            ) : (
              <Login setIsLoggedIn={setIsLoggedIn} />
            )
          }
        />
        <Route
          path="/home/*"
          element={
            isLoggedIn ? (
              <Home setIsLoggedIn={setIsLoggedIn} />
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />

        <Route
          path="/food-pickup/:id"
          element={
            isLoggedIn ? <FoodPickup /> : <Navigate to="/login" replace />
          }
        />

        <Route path="/" element={<Navigate to="/home" replace />} />
      </Routes>
    </BrowserRouter>
  );
};

export default App;
