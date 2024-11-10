import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RecipeGenerationPage extends StatefulWidget {
  const RecipeGenerationPage({super.key});

  @override
  _RecipeGenerationPageState createState() => _RecipeGenerationPageState();
}

class _RecipeGenerationPageState extends State<RecipeGenerationPage> {
  List<Map<String, dynamic>> _recipes = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    // Fetch email from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');  // Retrieve the email

    if (email == null) {
      print('No email found in local storage');
      return; // If no email is found, return early
    }

    // API URL
    const apiUrl = 'https://64ee-103-104-226-58.ngrok-free.app/recipe/send-recipes/';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',  // Ensure the Content-Type is set to JSON
        },
        body: json.encode({
          'email': email,  // Send email in the body as a JSON object
        }),
      );

      print('Email: $email');  // Debugging: print the email being sent
      print('Response Body: ${response.body}');  // Debugging: print the response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> receivedData = data['data']['received_data']['recipes']['recipes'];

        setState(() {
          _recipes = List<Map<String, dynamic>>.from(receivedData);
        });
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      print('Error fetching recipes: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Stories'),
      ),
      body: _recipes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Progress bars on top
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _recipes.asMap().entries.map((entry) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: LinearProgressIndicator(
                    value: entry.key == _currentIndex ? 1.0 : 0.0,
                    color: Colors.blue,
                    backgroundColor: Colors.grey[300],
                    minHeight: 4,
                  ),
                ),
              );
            }).toList(),
          ),
          Expanded(
            // PageView for swipe navigation
            child: PageView.builder(
              itemCount: _recipes.length,
              controller: PageController(viewportFraction: 1),
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final recipe = _recipes[index];
                return RecipeCard(recipe: recipe);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: recipe['image_url'] != null
                  ? Image.network(
                recipe['image_url'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 200,
                color: Colors.grey,
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe['description'] ?? 'No description available',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Prep: ${recipe['preparation_time'] ?? 'N/A'}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        "Cook: ${recipe['cooking_time'] ?? 'N/A'}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        "Difficulty: ${recipe['difficulty'] ?? 'Unknown'}",
                        style: TextStyle(
                          fontSize: 12,
                          color: recipe['difficulty'] == "Easy"
                              ? Colors.green
                              : recipe['difficulty'] == "Medium"
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Steps: ",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  recipe['steps'] != null && recipe['steps'] is List
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      recipe['steps'].length,
                          (stepIndex) {
                        return Text(
                          '${stepIndex + 1}. ${recipe['steps'][stepIndex]}',
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  )
                      : const Text(
                    'No steps available',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
