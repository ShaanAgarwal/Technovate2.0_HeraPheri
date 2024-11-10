import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Map.dart'; // Ensure the path is correct for Map.dart

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(), // The initial page will be HomePage
    );
  }
}

// HomePage with a list of donation IDs
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _donationIds = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDonationIds(); // Fetch donation IDs when the page loads
  }

  // Fetch donation IDs from the API
  Future<void> _fetchDonationIds() async {
    setState(() {
      _isLoading = true;
    });

    const String apiUrl = 'https://3432-103-104-226-58.ngrok-free.app/api/getDonationIds'; // Replace with your actual API URL

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Check if the response contains the success key and donationIds
        if (data['success'] == true && data['donationIds'] != null) {
          setState(() {
            // Populate donationIds with the list from the response
            _donationIds = List<String>.from(data['donationIds']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to fetch donation IDs. Please try again later.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load donation IDs. Please try again later.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator() // Show a loading spinner while fetching data
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // If we have donation IDs, display them in a rectangular format
            if (_donationIds.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Donation IDs:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Display the donation IDs inside a rectangular container
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _donationIds.map((id) {
                      return GestureDetector(
                        onTap: () {
                          // On clicking a donation ID, navigate to the Map page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Mapp(
                                19.888, // Use some sample coordinates for now
                                73.222, // Use some sample coordinates for now
                                id, // Pass the donation ID
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            id,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              )
            else if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
