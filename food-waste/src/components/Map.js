import React, { useEffect } from "react";
import { MapContainer, Marker, Popup, TileLayer, useMap } from "react-leaflet";
import L from "leaflet";
import "leaflet-routing-machine";
import axios from "axios";

const bikeIcon = L.icon({
  iconUrl: "/delivery-bike.png",
  iconSize: [50, 50],
  iconAnchor: [25, 50],
  popupAnchor: [0, -50],
});

const houseIcon = L.icon({
  iconUrl: "/house.png",
  iconSize: [50, 50],
  iconAnchor: [25, 50],
  popupAnchor: [0, -50],
});

const Routing = ({ driverLat, driverLng, houseLat, houseLng, donationId }) => {
  const map = useMap();

  useEffect(() => {
    const routingControl = L.Routing.control({
      waypoints: [L.latLng(driverLat, driverLng), L.latLng(houseLat, houseLng)],
      createMarker: () => null,
      routeWhileDragging: true,
      lineOptions: {
        styles: [
          {
            color: "blue",
            weight: 4,
            opacity: 0.6,
          },
        ],
      },
      show: true,
      collapsible: true,
      alternatives: false, // Disable alternative routes
    });

    // Add the routing control to the map
    routingControl.addTo(map);

    routingControl.on("routesfound", async function (event) {
      // Get the route from the event
      const route = event.routes[0];

      // Log the coordinates (lat, lng) of the route path
      const coordinates = route.coordinates;
      console.log("Route Coordinates:", coordinates);

      try {
        // Perform the async operation with axios
        console.log(donationId);
        const res = await axios.post(
          "https://3432-103-104-226-58.ngrok-free.app/api/send-path",
          { donationId, coordinates }
        );

        console.log(res);
      } catch (error) {
        // Handle errors from the axios request
        console.error("Error during the axios request:", error);
      }
    });

    // Cleanup on component unmount
    return () => {
      map.removeControl(routingControl);
    };
  }, [driverLat, driverLng, houseLat, houseLng, map]);

  return null;
};
export default function Map({ latitude, longitude, donationId }) {
  const driverLat = 19.1255;
  const driverLng = 72.834;
  const houseLat = latitude;
  const houseLng = longitude;

  return (
    <MapContainer
      center={[driverLat, driverLng]}
      zoom={13}
      scrollWheelZoom={false}
      className="rounded-lg"
    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      <Marker position={[driverLat, driverLng]} icon={bikeIcon}>
        <Popup>Driver Location</Popup>
      </Marker>
      <Marker position={[houseLat, houseLng]} icon={houseIcon}>
        <Popup>House Location</Popup>
      </Marker>
      <Routing
        driverLat={driverLat}
        driverLng={driverLng}
        houseLat={houseLat}
        houseLng={houseLng}
        donationId={donationId}
      />
    </MapContainer>
  );
}
