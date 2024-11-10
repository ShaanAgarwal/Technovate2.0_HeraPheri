import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapTrackingPage extends StatelessWidget {
  final String trackingId;
  final String foodName;
  final double latitude;
  final double longitude;

  const MapTrackingPage({
    super.key,
    required this.trackingId,
    required this.foodName,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking - $foodName'),
      ),
      body: Column(
        children: [
          // OpenStreetMap view
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                // zoom: 14.0,
                // Initial zoom level
                // Use the `center` directly
                initialCenter: LatLng(latitude, longitude), // Center the map at the coordinates
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'], // Subdomains for the OpenStreetMap tiles
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(latitude, longitude), // Marker position
                      width: 40.0,
                      height: 40.0,
                      // Use `child` instead of `builder`
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40.0, // Size of the location marker
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Display details below the map
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tracking ID: $trackingId',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Food Name: $foodName',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Latitude: $latitude',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Longitude: $longitude',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
