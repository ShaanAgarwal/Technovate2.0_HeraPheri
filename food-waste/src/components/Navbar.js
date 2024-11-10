import React from "react";
import { useNavigate } from "react-router-dom";

export const Navbar = ({ setIsLoggedIn }) => {
  const navigate = useNavigate();
  const handleLogout = () => {
    setIsLoggedIn(false);
    localStorage.clear();
    navigate("/login");
  };
  return (
    <nav className="bg-[#141C21] text-white px-20 py-1 flex justify-between items-center">
      <img src="/logo.png" alt="Food for Good Logo" className="h-12 w-15 " />{" "}
      <ul className="flex space-x-4">
        <li>
          <button onClick={() => navigate("/home")} className="hover:underline">
            Home
          </button>
        </li>
        {/* <li>
          <button
            onClick={() => navigate("/profile")}
            className="hover:underline"
          >
            Profile
          </button>
        </li>
        <li>
          <button
            onClick={() => navigate("/settings")}
            className="hover:underline"
          >
            Settings
          </button>
        </li> */}
        <li>
          <button onClick={handleLogout} className="hover:underline">
            Logout
          </button>
        </li>
      </ul>
    </nav>
  );
};
