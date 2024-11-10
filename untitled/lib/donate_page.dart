import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';  // Import geolocator for location fetching
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart';

class DonatePage extends StatefulWidget {
  const DonatePage({super.key});

  @override
  _DonatePageState createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  final _foodNameController = TextEditingController();
  final _sharingSizeController = TextEditingController();
  String _currentLocation = ""; // Store the fetched location

  // Method to fetch the current location of the user
  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(
          msg: "Location services are disabled. Please enable them.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );

        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(
            msg: "Location permission denied. Please allow it.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          return;
        }
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Update the location state
      setState(() {
        _currentLocation = "Lat: ${position.latitude}, Lon: ${position.longitude}";
        Fluttertoast.showToast(msg: _currentLocation);
      });
    } catch (e) {
      print('Error fetching location: $e');
      Fluttertoast.showToast(
        msg: "Error fetching location: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Method to submit the form and send the POST request with JSON
  Future<void> _submitForm() async {
    // Fetch the location when the user clicks on submit
    await _getCurrentLocation();

    if (_foodNameController.text.isNotEmpty &&
        _sharingSizeController.text.isNotEmpty &&
        _currentLocation.isNotEmpty) {

      // Get the access_token from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');  // Replace 'access_token' with your actual key

      if (accessToken == null || accessToken.isEmpty) {
        Fluttertoast.showToast(
          msg: "Access token is missing. Please log in again.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      // Prepare the data as a Map (for JSON body)
      Map<String, String> donationData = {
        'foodName': _foodNameController.text.toString(),
        'servingSize': _sharingSizeController.text.toString(),
        'location': _currentLocation.toString(), // Add the location to the request
      };

      // Convert the Map to JSON
      String jsonBody = json.encode(donationData);

      // Prepare the POST request
      var uri = Uri.parse('https://3432-103-104-226-58.ngrok-free.app/api/userDonationData'); // Replace with your API endpoint
      try {
        // Send the request as a JSON body
        var response = await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken', // Add token in Authorization header
            'Content-Type': 'application/json', // Set content type as JSON
          },
          body: jsonBody,
        );

        // Check if the response is successful
        if (response.statusCode == 201) {
          Fluttertoast.showToast(
            msg: "Donation Submitted Successfully!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          _foodNameController.clear();
          _sharingSizeController.clear();
          // Navigate to ProfilePage after successful donation
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),  // Navigate to ProfilePage
          );
        } else {
          Fluttertoast.showToast(
            msg: "Failed to submit donation. Please try again.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } catch (e) {
        print('Error submitting donation: $e');
        Fluttertoast.showToast(
          msg: "An error occurred while submitting donation.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: "Please fill in all fields and allow location access.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donate Food'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Donation Page',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Food Name TextField
              TextField(
                controller: _foodNameController,
                decoration: const InputDecoration(
                  labelText: 'Food Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              // Sharing Size TextField
              TextField(
                controller: _sharingSizeController,
                decoration: const InputDecoration(
                  labelText: 'Sharing Size',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              // Display current location (if fetched)
              if (_currentLocation.isNotEmpty)
                Text(
                  'Current Location: $_currentLocation',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              const SizedBox(height: 20),
              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit Donation'),
              ),
              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }
}