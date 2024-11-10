import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import 'signup_page.dart';
import 'profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Waste Tracker',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18, color: Colors.black),
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Food Waste Tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? imageUrl; // To store the URL of the random image

  @override
  void initState() {
    super.initState();
    _checkUserLoginStatus(); // Check user login status when the page loads
    _fetchRandomImage(); // Fetch a random image when the page loads
  }

  // Function to check if the user is logged in by looking at SharedPreferences
  Future<void> _checkUserLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('access_token');

    if (accessToken != null && accessToken.isNotEmpty) {
      // If an access token exists, redirect the user to the Profile page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  // Function to fetch a random image URL from Picsum
  Future<void> _fetchRandomImage() async {
    try {
      final response = await http.get(Uri.parse('https://picsum.photos/500?random=true'));

      if (response.statusCode == 200) {
        setState(() {
          imageUrl = response.request!.url.toString(); // Get the URL of the fetched image
        });
      } else {
        print('Failed to load image');
      }
    } catch (error) {
      print('Error fetching image: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.green.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Motivational Banner
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        'Welcome to the Food Waste Tracker!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Track food expiry, reduce waste, and donate to those in need.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Display random image fetched from Picsum API
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: imageUrl == null
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  ) // Loading indicator while image is being fetched
                      : Image.network(
                    imageUrl!, // Display the image
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),

                // Login Button with custom style
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to LoginPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(fontSize: 18),
                      backgroundColor: Colors.blueAccent, // Light blue color for login
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Rounded corners
                      ),
                      elevation: 5,
                    ),
                    child: const Text('Login'),
                  ),
                ),

                const SizedBox(height: 15),

                // Sign Up Button with custom style
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to SignUpPage
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(fontSize: 18),
                      backgroundColor: Colors.orangeAccent, // Light orange color for signup
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Rounded corners
                      ),
                      elevation: 5,
                    ),
                    child: const Text('Sign Up'),
                  ),
                ),

                // Footer with motivational message
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Together, we can make a difference!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
