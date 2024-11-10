import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'map_tracking_page.dart';  // Import the MapTrackingPage

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  bool _isLoading = true; // To show the loading indicator
  String _errorMessage = ''; // To show any error messages
  List<Map<String, dynamic>> _trackings = []; // List to hold tracking data

  @override
  void initState() {
    super.initState();
    _fetchTrackingData(); // Call the function to fetch tracking data when the page opens
  }

  // Function to fetch the access token from SharedPreferences
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token'); // Retrieve the access token
  }

  // Function to fetch tracking data from the API
  Future<void> _fetchTrackingData() async {
    const String apiUrl = 'https://3432-103-104-226-58.ngrok-free.app/api/getdonationtrackingdata'; // Replace with your actual API URL

    // Fetch the access token from SharedPreferences
    String? accessToken = await _getAccessToken();

    if (accessToken == null) {
      setState(() {
        _errorMessage = 'Access token is missing. Please log in again.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      print(response.body);

      if (response.statusCode == 200) {
        // If the request was successful, parse the response body
        final data = json.decode(response.body);

        // Extract the 'pickupReq' data
        final List<dynamic> pickupReq = data['pickupReq'];

        setState(() {
          _trackings = pickupReq.map((item) {
            return {
              'id': item['_id'],
              'foodName': item['foodName'],
              'latitude': item['location']['coordinates'][1],  // Extract latitude
              'longitude': item['location']['coordinates'][0], // Extract longitude
            };
          }).toList();
          _isLoading = false; // Set loading to false after data is loaded
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load tracking data. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to connect to the server. Error: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator while fetching data
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _trackings.length,
          itemBuilder: (context, index) {
            final tracking = _trackings[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text('Tracking ID: ${tracking['id']}'),
                subtitle: Text(
                  'Food Name: ${tracking['foodName']}',
                ),
                onTap: () {
                  // Navigate to the MapTrackingPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapTrackingPage(
                        trackingId: tracking['id'],
                        foodName: tracking['foodName'],
                        latitude: tracking['latitude'],
                        longitude: tracking['longitude'],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
