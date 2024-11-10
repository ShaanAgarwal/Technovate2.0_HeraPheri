import React, { useEffect, useState } from "react";
import { useParams, useNavigate, redirect } from "react-router-dom";
import axios from "axios";
import Map from "../components/Map";
import {
  ArrowLeft,
  MapPin,
  Users,
  Clock,
  Package,
  AlertCircle,
  Loader2,
} from "lucide-react";
import { Navbar } from "../components/Navbar";
import { toast } from "sonner";

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

const DetailItem = ({ icon: Icon, label, value }) => (
  <div className="flex items-start space-x-3 py-3">
    <div className="flex-shrink-0">
      <Icon className="w-5 h-5 text-gray-500" />
    </div>
    <div>
      <p className="text-sm font-medium text-gray-500">{label}</p>
      <p className="mt-1 text-base text-gray-900">{value}</p>
    </div>
  </div>
);

const LoadingState = () => (
  <div className="min-h-screen flex items-center justify-center bg-gray-50">
    <div className="text-center">
      <Loader2 className="w-8 h-8 text-blue-500 animate-spin mx-auto" />
      <p className="mt-2 text-gray-600">Loading pickup details...</p>
    </div>
  </div>
);

const ErrorState = ({ message }) => (
  <div className="min-h-screen flex items-center justify-center bg-gray-50">
    <div className="text-center">
      <AlertCircle className="w-8 h-8 text-red-500 mx-auto" />
      <p className="mt-2 text-red-600">{message}</p>
      {console.log(message)}
    </div>
  </div>
);

const FoodPickup = () => {
  const [pickup, setPickup] = useState(null);
  const [isScheduled, setIsScheduled] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [isUpdating, setIsUpdating] = useState(false);
  const navigate = useNavigate();
  const { id } = useParams();

  useEffect(() => {
    fetchPickupData();
  }, [id]);

  const fetchPickupData = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const storedData = localStorage.getItem("ngoData");
      if (!storedData) {
        throw new Error("Authentication data not found");
      }

      const { access_token } = JSON.parse(storedData);
      const response = await axios.post(
        "https://3432-103-104-226-58.ngrok-free.app/api/getPickupData",
        {},
        {
          headers: {
            Authorization: `Bearer ${access_token}`,
          },
        }
      );

      const selectedPickup = response.data.pickupReq.find(
        (request) => request._id === id
      );

      if (selectedPickup) {
        setPickup(selectedPickup);
        setIsScheduled(
          selectedPickup.status === "scheduled" ||
            selectedPickup.status === "in_progress"
        );
      } else {
        throw new Error("Pickup request not found!");
      }
    } catch (error) {
      setError(error.message);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSchedulePickup = async () => {
    setIsUpdating(true);
    try {
      // Add your API call here to update the status
      setIsScheduled(true);
      // Show success toast or message
    } catch (error) {
      // Show error toast or message
    } finally {
      setIsUpdating(false);
    }
  };

  const handleCancelPickup = async () => {
    setIsUpdating(true);
    try {
      const storedData = localStorage.getItem("ngoData");
      if (!storedData) {
        throw new Error("Authentication data not found");
      }

      const { access_token } = JSON.parse(storedData);

      console.log(access_token);

      // Make an API call to cancel the pickup
      const response = await axios.delete(
        "https://3432-103-104-226-58.ngrok-free.app/api/cancelPickup",
        { pickupId: id },
        {
          headers: {
            Authorization: `Bearer ${access_token}`,
          },
        }
      );

      if (response.data.message === "Pickup canceled successfully") {
        navigate("/pickups"); // Navigate to the pickups list or relevant page
      } else {
        throw new Error("Failed to cancel pickup");
      }
    } catch (error) {
      toast.error(`Error: ${error.message}`);
    } finally {
      setIsUpdating(false);
    }
  };

  if (isLoading) return <LoadingState />;
  if (error) return <ErrorState message={error} />;
  if (!pickup) return <ErrorState message="Pickup details not found" />;

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <button
          onClick={() => navigate(-1)}
          className="flex items-center text-gray-600 hover:text-gray-900 transition-colors mb-6"
        >
          <ArrowLeft className="w-5 h-5 mr-2" />
          Back to Pickups
        </button>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Details Panel */}
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden lg:col-span-1">
            <div className="p-6">
              <div className="flex justify-between items-start mb-6">
                <h2 className="text-2xl font-bold text-gray-900">
                  Pickup Details
                </h2>
                <StatusBadge status={pickup.status} />
              </div>

              <div className="divide-y divide-gray-200">
                <DetailItem
                  icon={MapPin}
                  label="Pickup Location"
                  value={pickup.pickupLocation.coordinates.join(", ")}
                />
                <DetailItem
                  icon={Package}
                  label="Food Items"
                  value={pickup.foodName}
                />
                <DetailItem
                  icon={Users}
                  label="Serving Size"
                  value={pickup.servingSize}
                />
                <DetailItem
                  icon={Clock}
                  label="Created At"
                  value={new Date(pickup.createdAt).toLocaleDateString()}
                />
              </div>

              {!isScheduled && (
                <div className="mt-6 flex space-x-4">
                  <button
                    onClick={handleSchedulePickup}
                    disabled={isUpdating}
                    className="flex-1 px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                  >
                    {isUpdating ? "Scheduling..." : "Schedule Pickup"}
                  </button>
                  <button
                    onClick={handleCancelPickup}
                    disabled={isUpdating}
                    className="flex-1 px-4 py-2 bg-red-600 text-white text-sm font-medium rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                  >
                    {isUpdating ? "Cancelling..." : "Cancel Pickup"}
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* Map Panel */}
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden lg:col-span-2">
            <div className="p-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">
                Pickup Location
              </h3>
              <div className="h-[500px] rounded-lg overflow-hidden">
                <Map
                  latitude={pickup.pickupLocation.coordinates[1]}
                  longitude={pickup.pickupLocation.coordinates[0]}
                  donationId={id}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FoodPickup;
