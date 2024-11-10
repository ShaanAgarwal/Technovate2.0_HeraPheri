import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class Mapp extends StatefulWidget {
  final double destinationLatitude;
  final double destinationLongitude;
  final String donationId; // Adding the donation ID parameter

  const Mapp(this.destinationLatitude, this.destinationLongitude, this.donationId);

  @override
  _MappState createState() => _MappState();
}

class _MappState extends State<Mapp> {
  late Location _location;
  late LocationData _currentLocation;
  late StreamSubscription<LocationData> _locationSubscription;
  double? _latitude;
  double? _longitude;

  List<LatLng> _routeCoordinates = [];
  List<LatLng> _extraCoordinates = []; // For additional coordinates fetched from API

  @override
  void initState() {
    super.initState();
    _location = Location();

    // Request permission for location
    _location.requestPermission().then((granted) {
      if (granted == PermissionStatus.granted) {
        // Start listening to location changes
        _locationSubscription =
            _location.onLocationChanged.listen((LocationData currentLocation) {
              setState(() {
                _latitude = currentLocation.latitude;
                _longitude = currentLocation.longitude;
              });
              // Request route whenever the location changes
              if (_latitude != null && _longitude != null) {
                _fetchRoute(_latitude!, _longitude!, widget.destinationLatitude, widget.destinationLongitude);
                // Fetch additional coordinates using the donation ID
                _fetchAdditionalCoordinates(widget.donationId);
              }
            });
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription.cancel();
    super.dispose();
  }

  // Fetch the route from OpenRouteService API
  Future<void> _fetchRoute(double startLat, double startLon, double endLat, double endLon) async {
    const apiKey = '5b3ce3597851110001cf624863009419395243e5be4ab8b01023d35c'; // Replace with your API key
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$startLon,$startLat&end=$endLon,$endLat',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Get route coordinates for the polyline
        final route = data['routes'][0]['geometry']['coordinates'] as List;
        List<LatLng> coordinates = route.map((e) {
          return LatLng(e[1], e[0]);
        }).toList();

        setState(() {
          _routeCoordinates = coordinates;
        });
      } else {
        throw Exception('Failed to load route');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  // Fetch additional coordinates based on the donation ID
  Future<void> _fetchAdditionalCoordinates(String donationId) async {
    final apiUrl = 'https://3432-103-104-226-58.ngrok-free.app/api/getCoordinates'; // Replace with your actual API URL
    final headers = {"Content-Type": "application/json"};
    final body = json.encode({
      'donationId': donationId,
    });

    try {
      final response = await http.post(Uri.parse(apiUrl), headers: headers, body: body); // POST request
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Assuming the API response contains a list of coordinates
        final extraCoords = data['coordinates'] as List;

        List<LatLng> coordinates = [];
        for (var coord in extraCoords) {
          // Check if lat and lng are not null before creating the LatLng object
          if (coord['lat'] != null && coord['lng'] != null) {
            coordinates.add(LatLng(coord['lat'], coord['lng']));
          }
        }

        setState(() {
          _extraCoordinates = coordinates;
        });
      } else {
        throw Exception('Failed to load additional coordinates');
      }
    } catch (e) {
      print('Error fetching additional coordinates: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double latitude = _latitude ?? widget.destinationLatitude;
    double longitude = _longitude ?? widget.destinationLongitude;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking and Navigation'),
      ),
      body: Column(
        children: [
          // OpenStreetMap view
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(_extraCoordinates[0].latitude, _extraCoordinates[0].longitude), // Center the map at the current location
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'], // Subdomains for the OpenStreetMap tiles
                ),
                MarkerLayer(
                  markers: [
                    // Current Location Marker
                    Marker(
                      point: LatLng(_extraCoordinates[0].latitude, _extraCoordinates[0].longitude), // Current location marker
                      width: 40.0,
                      height: 40.0,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40.0,
                      ),
                    ),
                    // Destination Marker
                    Marker(
                      point: LatLng(_extraCoordinates[_extraCoordinates.length - 1].latitude, _extraCoordinates[_extraCoordinates.length - 1].longitude), // Destination marker
                      width: 40.0,
                      height: 40.0,
                      child: const Icon(
                        Icons.flag,
                        color: Colors.green,
                        size: 40.0,
                      ),
                    ),
                    // Additional markers from fetched coordinates
                    ..._extraCoordinates.map((coord) {
                      return Marker(
                        point: coord,
                        width: 20.0,
                        height: 20.0,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 20.0,
                        ),
                      );
                    }).toList(),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    // Route Polyline (Blue line)
                    Polyline(
                      points: _routeCoordinates,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                    // Additional Polyline (Red line connecting fetched coordinates)
                    Polyline(
                      points: _extraCoordinates,
                      strokeWidth: 4.0,
                      color: Colors.red, // The red line for additional coordinates
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
