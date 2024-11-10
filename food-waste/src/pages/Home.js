import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Navbar } from "../components/Navbar";
import axios from "axios";
import { Loader2, MapPin, Users, Clock, AlertCircle } from "lucide-react";
import Map from "../components/Map";

const StatusBadge = ({ status }) => {
  const getStatusStyle = () => {
    switch (status?.toLowerCase()) {
      case "completed":
        return "bg-green-100 text-green-800";
      case "in_progress":
        return "bg-blue-100 text-blue-800";
      case "cancelled":
        return "bg-red-100 text-red-800";
      default:
        return "bg-yellow-100 text-yellow-800";
    }
  };

  return (
    <span
      className={`px-3 py-1 rounded-full text-sm font-medium ${getStatusStyle()}`}
    >
      {status || "Pending"}
    </span>
  );
};

const PickupCard = ({ request, onClick }) => {
  const formatCoordinates = (coordinates) => {
    if (!coordinates || !Array.isArray(coordinates))
      return "Location unavailable";
    return `${coordinates[0].toFixed(6)}, ${coordinates[1].toFixed(6)}`;
  };

  return (
    <div
      onClick={onClick}
      className="bg-white shadow-sm hover:shadow-md transition-shadow duration-200 rounded-lg p-6 border border-gray-200 cursor-pointer"
    >
      <div className="flex justify-between items-start mb-4">
        <h3 className="text-lg font-semibold text-gray-900 flex-1">
          {request.foodName}
        </h3>
        <StatusBadge status={request.status} />
      </div>

      <div className="space-y-2 text-sm text-gray-600">
        <div className="flex items-center gap-2">
          <MapPin className="w-4 h-4" />
          <span>{formatCoordinates(request.pickupLocation?.coordinates)}</span>
        </div>

        <div className="flex items-center gap-2">
          <Users className="w-4 h-4" />
          <span>Serving Size: {request.servingSize}</span>
        </div>

        {/* <div className="flex items-center gap-2">
          <Clock className="w-4 h-4" />
          <span>
            Created: {new Date(request.createdAt).toLocaleDateString()}
          </span>
        </div> */}
      </div>
    </div>
  );
};

const ErrorMessage = ({ message }) => (
  <div className="flex items-center justify-center p-4 bg-red-50 rounded-lg">
    <AlertCircle className="w-5 h-5 text-red-500 mr-2" />
    <p className="text-red-600">{message}</p>
  </div>
);

const LoadingState = () => (
  <div className="flex items-center justify-center p-8">
    <Loader2 className="w-6 h-6 text-blue-500 animate-spin" />
    <span className="ml-2 text-gray-600">Loading pickup requests...</span>
  </div>
);

const Home = ({ setIsLoggedIn }) => {
  const [pickupRequests, setPickupRequests] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    getPickupData();
  }, []);

  const getPickupData = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const storedData = localStorage.getItem("ngoData");
      if (!storedData) {
        throw new Error("Authentication data not found");
      }

      const { id, access_token } = JSON.parse(storedData);

      const response = await axios.post(
        "https://3432-103-104-226-58.ngrok-free.app/api/getPickupData",
        {},
        {
          headers: {
            Authorization: `Bearer ${access_token}`,
          },
        }
      );

      setPickupRequests(response.data.pickupReq);
    } catch (error) {
      console.error("Failed to fetch pickup requests:", error);
      setError(
        error.response?.data?.message ||
          error.message ||
          "Failed to fetch pickup requests"
      );
    } finally {
      setIsLoading(false);
    }
  };

  const goToPickupDetails = (id) => {
    navigate(`/food-pickup/${id}`);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar setIsLoggedIn={setIsLoggedIn} />

      <main className="container mx-auto px-4 py-8 max-w-5xl">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold text-gray-900">
            Food Pickup Requests
          </h1>
          <button
            onClick={getPickupData}
            className="px-4 py-2 text-sm font-medium text-blue-600 hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 rounded-md"
          >
            Refresh
          </button>
        </div>

        {isLoading ? (
          <LoadingState />
        ) : error ? (
          <ErrorMessage message={error} />
        ) : pickupRequests.length === 0 ? (
          <div className="text-center py-12 bg-white rounded-lg shadow-sm">
            <p className="text-gray-500">No pickup requests found</p>
          </div>
        ) : (
          <div className="grid gap-4 md:grid-cols-2">
            {pickupRequests.map((request) => (
              <PickupCard
                key={request._id}
                request={request}
                onClick={() => goToPickupDetails(request._id)}
              />
            ))}
          </div>
        )}
      </main>
    </div>
  );
};

export default Home;
