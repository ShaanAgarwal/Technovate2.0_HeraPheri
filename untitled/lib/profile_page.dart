import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'main.dart';
import 'donate_page.dart';
import 'tracking.dart';
import 'recipe_generation_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _email;
  String? _username;
  String? _accessToken;

  // Food items list to store data
  List<Map<String, dynamic>> _foodItems = [];

  // Controller for the form fields in the dialog
  TextEditingController _itemNameController = TextEditingController();
  TextEditingController _quantityController = TextEditingController();
  String _quantityUnit = 'Units'; // Default unit
  DateTime? _expiryDate;

  // Loading state for fetching food items
  bool _isLoading = false;

  // List of story images using picsum.photos
  final List<String> _storyImages = [
    'https://picsum.photos/200/200?random=1',
    'https://picsum.photos/250/250?random=2',
    'https://picsum.photos/300/300?random=3',
    'https://picsum.photos/350/350?random=4',
    'https://picsum.photos/400/400?random=5',
  ];

  int? _activeStoryIndex;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data from SharedPreferences
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString('email');
      _username = prefs.getString('username');
      _accessToken = prefs.getString('access_token');
    });

    if (_accessToken != null) {
      // Fetch food items if the access token is available
      await _fetchFoodItems();
    }
  }

  // Fetch food items from the API
  Future<void> _fetchFoodItems() async {
    setState(() {
      _isLoading = true; // Set loading state to true
    });

    const String apiUrl = 'https://3432-103-104-226-58.ngrok-free.app/api/getitems'; // Replace with your API URL

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
      );
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _foodItems = List<Map<String, dynamic>>.from(data['foodItems']);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load food items. Status: ${response.statusCode}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to the server.')),
      );
      print('Error: $error');
    } finally {
      setState(() {
        _isLoading = false; // Set loading state to false
      });
    }
  }

  // Function to show the modal dialog for the story (recipe modal)
  void _showRecipeModal(String storyImage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recipe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Story image
              Image.network(storyImage),
              const SizedBox(height: 16),
              const Text('This is the recipe text for the selected item.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Function to show the modal dialog for adding food item
  void _showAddFoodItemDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Food Item'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Food Item Name
                TextField(
                  controller: _itemNameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Quantity Input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dropdown for unit (Units or kg)
                    DropdownButton<String>(
                      value: _quantityUnit, // Ensure the selected value is bound to state
                      items: <String>['Units', 'kg']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _quantityUnit = newValue!; // Update the state and trigger UI rebuild
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Expiry Date Picker
                GestureDetector(
                  onTap: () async {
                    DateTime? selectedDate = await showDatePicker(
                      context: context,
                      initialDate: _expiryDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (selectedDate != null && selectedDate != _expiryDate) {
                      setState(() {
                        _expiryDate = selectedDate; // Update state to trigger rebuild
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _expiryDate == null
                          ? 'Select Date' // Placeholder text if no date is selected
                          : DateFormat('yyyy-MM-dd').format(_expiryDate!),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            // Add Button
            TextButton(
              onPressed: () {
                _addFoodItem(); // Call the API to add the food item
                _clearForm(); // Clear the form after adding
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }


// Function to clear form fields
  void _clearForm() {
    // Reset controllers and state
    _itemNameController.clear();
    _quantityController.clear();
    setState(() {
      _quantityUnit = 'Units'; // Reset the dropdown to default
      _expiryDate = null; // Reset the expiry date to null
    });
  }


  // Function to send a POST request and add the food item
  Future<void> _addFoodItem() async {
    // Prepare the data to send in the request
    final itemData = {
      'name': _itemNameController.text,
      'quantity': _quantityController.text,
      'unit': _quantityUnit,
      'expiry_date': _expiryDate != null
          ? DateFormat('yyyy-MM-dd').format(_expiryDate!)
          : null,
      'access_token': _accessToken
    };

    const String apiUrl = 'https://3432-103-104-226-58.ngrok-free.app/api/additem';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode(itemData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item created successfully!')),
        );
        // Fetch the updated list of food items
        await _fetchFoodItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create item. Status: ${response.statusCode}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to the server.')),
      );
      print('Error: $error');
    } finally {
      // Close the dialog
      Navigator.of(context).pop();
    }
  }

  // Function to handle logout and clear local storage
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored preferences
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Food Waste Tracker')),
    );
  }
  Future<void> _deleteFoodItem(String itemId) async {
    print(itemId);
    const String apiUrl = 'https://3432-103-104-226-58.ngrok-free.app/api/deleteitem'; // Replace with your API URL

    try {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode({
          'itemId': itemId, // Sending itemId in the body of the request
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully!')),
        );
        // After deletion, fetch the updated list of food items
        await _fetchFoodItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item. Status: ${response.statusCode}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to the server.')),
      );
      print('Error: $error');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // Plus button to add food item
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddFoodItemDialog, // Show dialog when clicked
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Welcome!',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Logout'),
              onTap: _logout, // Call the logout function
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Generate Recipe'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const RecipeGenerationPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_hospital),
              title: const Text('Donate Food'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DonatePage()),
                );
              },
            ),
            // New "Tracking" button in the drawer
            ListTile(
              leading: const Icon(Icons.track_changes),
              title: const Text('Tracking'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrackingPage()), // Navigate to the Tracking page
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instagram-style story section at the top
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _storyImages.length,
                itemBuilder: (context, index) {
                  final isActive = _activeStoryIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeStoryIndex = isActive ? null : index; // Toggle active story
                        });
                        _showRecipeModal(_storyImages[index]);
                      },
                      child: CircleAvatar(
                        radius: 30, // Default size
                        backgroundImage: NetworkImage(_storyImages[index]),
                        backgroundColor: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive ? Colors.blue : Colors.white,
                              width: isActive ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Displaying email, username, and access token from local storage
            if (_email != null)
              Text('Email: $_email', style: const TextStyle(fontSize: 18)),
            if (_username != null)
              Text('Username: $_username', style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 20), // Add some space before food list

            // Food items list
            const Text(
              'Food Items:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Loading indicator while fetching food items
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),

            // Display the list of food items
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _foodItems.map((foodItem) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(foodItem['name'] ?? 'No name'),
                        subtitle: Text('Quantity: ${foodItem['quantity']} ${foodItem['unit'] }${foodItem['dateAdded'] != null ? '\nExpiry Date: ${foodItem['expiry_date']}' : ''}'),
                        trailing: IconButton(onPressed: ()=>{
                          _deleteFoodItem(foodItem['_id'])
                        }, icon: const Icon(Icons.delete,color: Colors.red,) ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Donate Food Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DonatePage()),
                  );
                },
                child: const Text('Donate Food'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}