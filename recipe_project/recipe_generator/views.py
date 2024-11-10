# recipe_generator/views.py
from django.views.decorators.csrf import csrf_exempt
import requests
from django.shortcuts import render
from django.http import JsonResponse
from django.conf import settings
from django.views.decorators.csrf import ensure_csrf_cookie, csrf_exempt  # Add this import
from django.views.decorators.http import require_POST
import google.generativeai as genai
import json
import re
import os
from pathlib import Path
from dotenv import load_dotenv
from pymongo import MongoClient
from bson import json_util
import requests
import google.generativeai as genai
from django.core.validators import validate_email
from django.core.exceptions import ValidationError


def generate_prompt(ingredients_list):

    prompt = """As a professional global chef (of Indian origin), analyze these ingredients and create 4-6 possible authentic recipes (at least 1 catered towards an Indian audience):

    Available Ingredients:
    {ingredients}

    Instructions:
    1. Generate 4-6 different recipes that can be made using SOME OR ALL of these ingredients
    2. Each recipe must be practical and authentic Indian cuisine
    3. Use PRECISE measurements in the steps (e.g., "heat oil to 350°F", "simmer for exactly 12 minutes", "add ¾ teaspoon")
    4. Steps should be extremely detailed like in a professional cookbook
    5. Make the steps - contain multiple substeps; and take into consideration multiple other aspects as well (apart from the ones mentioned)
    6. Consider cooking techniques, temperatures, and timing
    7. Stay within the bounds of given ingredient quantities
    8. Not all ingredients need to be used in each recipe
    9. Make the recipes non-repetitive and unique; while being based in reality
    10. Specify the dish name, cooking time, and serving size for each recipe
    11. If possible, include a brief description of the dish and its origin

    Respond with ONLY this valid JSON - no other text:
    {{
        "recipes": [
            {{
                "title": "First Recipe Name",
                "description": "Brief 1-2 line description of the dish",
                "preparation_time": "X minutes",
                "cooking_time": "Y minutes",
                "difficulty": "Easy/Medium/Hard",
                "steps": [
                    "Step 1: Extremely detailed instruction with exact measurements and timing",
                    "Step 2: Next detailed instruction..."
                ]
            }},
            {{
                "title": "Second Recipe Name",
                "description": "Brief 1-2 line description of the dish",
                "preparation_time": "X minutes",
                "cooking_time": "Y minutes",
                "difficulty": "Easy/Medium/Hard",
                "steps": [
                    "Step 1: Extremely detailed instruction with exact measurements and timing",
                    "Step 2: Next detailed instruction..."
                ]
            }}
        ]
    }}

    Requirements for steps:
    - Use exact measurements (e.g., "¾ cup", "2 tablespoons", "350°F")
    - Include precise timing (e.g., "sauté for exactly 5 minutes", "simmer for 12-15 minutes")
    - Specify cooking temperatures
    - Describe visual cues ("until golden brown", "until edges start to curl")
    - Include technique details ("stirring occasionally", "on medium-high heat")
    - Add sensory indicators ("until fragrant", "until onions are translucent")
    - Specify equipment needed ("in a heavy-bottomed pan", "using a wooden spoon")
    - Include recipes of each difficulty at least once; and give them in ascending order of difficulty
    - Make the categorization of difficulty based on multiple parameters and overall complexity of the dish
    - If someone has put only vegetarian ingredients; do not recommend a non - vegetarian recipe
    - Ensure that all the ingredients get used at least once in all the recipes"""

    ingredients_text = "\n".join(
        [f"- {item['quantity']} {item['name']}" for item in ingredients_list])
    return prompt.format(ingredients=ingredients_text)


def extract_json_from_text(text):
    """Extract JSON object from text, handling various formats"""
    # Remove any markdown formatting
    text = re.sub(r'```json\s*', '', text)
    text = re.sub(r'```\s*', '', text)

    # Try to find JSON object
    match = re.search(r'\{[\s\S]*\}', text)
    if match:
        return match.group(0)
    return None


def index(request):
    return render(request, 'recipe_generator/index.html')


def generate_recipe(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            ingredients = data.get('ingredients', [])

            # print(f"Received ingredients: {ingredients}")

            genai.configure(api_key=settings.GEMINI_API_KEY)
            model = genai.GenerativeModel('gemini-1.5-flash')

            prompt = generate_prompt(ingredients)
            # print(f"Generated prompt: {prompt}")

            response = model.generate_content(
                prompt,
                generation_config={
                    'temperature': 0.7,
                    'top_p': 0.8,
                    'top_k': 40,
                    'max_output_tokens': 4096,  # Increased for multiple recipes
                }
            )

            # print(f"Raw API Response: {response.text}")

            json_str = extract_json_from_text(response.text)
            if not json_str:
                print("Failed to extract JSON from response")
                return JsonResponse({
                    'error': 'Invalid response format from AI'
                }, status=500)

            # print(f"Extracted JSON string: {json_str}")

            try:
                recipe_data = json.loads(json_str)

                # Validate response structure
                if not isinstance(recipe_data, dict):
                    raise ValueError("Response is not a dictionary")
                if 'recipes' not in recipe_data:
                    raise ValueError("Missing recipes array")
                if not isinstance(recipe_data['recipes'], list):
                    raise ValueError("Recipes is not a list")
                if not recipe_data['recipes']:
                    raise ValueError("No recipes generated")

                # Validate each recipe
                for recipe in recipe_data['recipes']:
                    if not isinstance(recipe, dict):
                        raise ValueError("Recipe is not a dictionary")
                    if 'title' not in recipe:
                        raise ValueError("Recipe missing title")
                    if 'steps' not in recipe:
                        raise ValueError("Recipe missing steps")
                    if not isinstance(recipe['steps'], list):
                        raise ValueError("Recipe steps is not a list")

                return JsonResponse(recipe_data)

            except json.JSONDecodeError as e:
                print(f"JSON Decode Error: {str(e)}")
                print(f"Problematic JSON string: {json_str}")
                return JsonResponse({
                    'error': 'Failed to parse recipe JSON'
                }, status=500)

        except Exception as e:
            print(f"General Error: {str(e)}")
            return JsonResponse({
                'error': str(e)
            }, status=500)

    return JsonResponse({'error': 'Invalid request method'}, status=400)

# views.py


# Your ngrok URL (replace with your actual ngrok URL)
NGROK_URL = 'https://64ee-103-104-226-58.ngrok-free.app/recipe/receive-recipes/'

# Sample recipe data
SAMPLE_RECIPES = [
    {
        "title": "Butter Chicken",
        "description": "Creamy, rich and mildly spiced chicken curry",
        "preparation_time": "30 mins",
        "cooking_time": "45 mins",
        "difficulty": "Medium",
        "image_url": "https://www.indianhealthyrecipes.com/wp-content/uploads/2023/04/butter-chicken-recipe.jpg",
        "steps": [
            "Marinate chicken with yogurt and spices for 2 hours",
            "Prepare the tomato-based curry sauce with butter and cream",
            "Cook marinated chicken until tender",
            "Combine chicken with the curry sauce",
            "Garnish with fresh cream and coriander"
        ]
    },
    {
        "title": "Palak Paneer",
        "description": "Cottage cheese cubes in creamy spinach gravy",
        "preparation_time": "20 mins",
        "cooking_time": "30 mins",
        "difficulty": "Easy",
        "image_url": "https://www.indianhealthyrecipes.com/wp-content/uploads/2020/06/palak-paneer-recipe.jpg",
        "steps": [
            "Blanch and puree spinach leaves",
            "Saute spices and onions until golden",
            "Add spinach puree and cook",
            "Add paneer cubes and simmer",
            "Finish with cream and butter"
        ]
    },
    # Add other recipes here...
]

NGROK_URL = 'https://64ee-103-104-226-58.ngrok-free.app/recipe/receive-recipes/'

SAMPLE_RECIPES = [
    {
        "title": "Butter Chicken",
        "description": "Creamy, rich and mildly spiced chicken curry",
        "preparation_time": "30 mins",
        "cooking_time": "45 mins",
        "difficulty": "Medium",
        "image_url": "https://www.indianhealthyrecipes.com/wp-content/uploads/2023/04/butter-chicken-recipe.jpg",
        "steps": [
            "Marinate chicken with yogurt and spices for 2 hours",
            "Prepare the tomato-based curry sauce with butter and cream",
            "Cook marinated chicken until tender",
            "Combine chicken with the curry sauce",
            "Garnish with fresh cream and coriander"
        ]
    },
    {
        "title": "Palak Paneer",
        "description": "Cottage cheese cubes in creamy spinach gravy",
        "preparation_time": "20 mins",
        "cooking_time": "30 mins",
        "difficulty": "Easy",
        "image_url": "https://www.indianhealthyrecipes.com/wp-content/uploads/2020/06/palak-paneer-recipe.jpg",
        "steps": [
            "Blanch and puree spinach leaves",
            "Saute spices and onions until golden",
            "Add spinach puree and cook",
            "Add paneer cubes and simmer",
            "Finish with cream and butter"
        ]
    },
    {
        "title": "Biryani",
        "description": "Aromatic rice dish with spices and vegetables",
        "preparation_time": "40 mins",
        "cooking_time": "50 mins",
        "difficulty": "Hard",
        "image_url": "https://i.ytimg.com/vi/NtuIRDuIvgs/maxresdefault.jpg",
        "steps": [
            "Prepare the biryani masala",
            "Cook rice till 70% done",
            "Layer the rice with vegetables and masala",
            "Seal and cook on dum",
            "Garnish with fried onions and mint"
        ]
    },
    {
        "title": "Dal Makhani",
        "description": "Creamy black lentils simmered overnight",
        "preparation_time": "8 hours",
        "cooking_time": "4 hours",
        "difficulty": "Medium",
        "image_url": "https://www.awesomecuisine.com/wp-content/uploads/2014/06/dal-makhani.jpg",
        "steps": [
            "Soak the lentils overnight",
            "Pressure cook lentils until soft",
            "Prepare tomato-based gravy",
            "Simmer with cream and butter",
            "Finish with fresh cream and garam masala"
        ]
    },
    {
        "title": "Chana Masala",
        "description": "Spiced chickpeas curry",
        "preparation_time": "15 mins",
        "cooking_time": "40 mins",
        "difficulty": "Easy",
        "image_url": "https://www.allrecipes.com/thmb/siVGrqeV5Q7xvRGaWWA_5ph9Dds=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/236564-chana-masala-savory-indian-chick-peas-3x4-672-copy-63ae3db5114644419c313cd0e479c9dd.jpg",
        "steps": [
            "Soak and cook chickpeas",
            "Prepare onion-tomato masala",
            "Add spices and chickpeas",
            "Simmer until thick",
            "Garnish with coriander and ginger"
        ]
    }
]

# recipe_generator/views.py

# Your SAMPLE_RECIPES dictionary remains the same

# Get the path to the recipe-project directory (parent of current directory)
BASE_DIR = Path(__file__).resolve().parent.parent

# Load environment variables from .env file in the project root
load_dotenv(os.path.join(BASE_DIR, '.env'))


def parse_json(data):
    return json.loads(json_util.dumps(data))


def connect_to_mongodb():
    try:
        mongo_uri = os.getenv('MONGO_DB_URL')
        if not mongo_uri:
            raise ValueError("MongoDB URI not found in environment variables")
        client = MongoClient(mongo_uri)
        client.admin.command('ping')
        print("Successfully connected to MongoDB!")
        return client
    except Exception as e:
        print(f"Error connecting to MongoDB: {str(e)}")
        return None


def transform_food_items(food_items):
    return [
        {
            'name': item['name'],
            'quantity': f"{item['quantity']} {item['unit']}"
        }
        for item in food_items
    ]


def generate_recipes_from_ingredients(ingredients):
    try:
        genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
        model = genai.GenerativeModel('gemini-1.5-flash')
        prompt = generate_prompt(ingredients)

        print("\nGenerating recipes...")
        response = model.generate_content(
            prompt,
            generation_config={
                'temperature': 0.7,
                'top_p': 0.8,
                'top_k': 40,
                'max_output_tokens': 4096,
            }
        )

        json_str = extract_json_from_text(response.text)
        if not json_str:
            print("Failed to extract JSON from response")
            return None

        try:
            recipe_data = json.loads(json_str)
            return recipe_data
        except json.JSONDecodeError as e:
            print(f"JSON Decode Error: {str(e)}")
            return None

    except Exception as e:
        print(f"Error generating recipes: {str(e)}")
        return None


@require_POST
def fetch_and_generate_recipes(request):
    email = request.POST.get('email')
    if not email:
        return JsonResponse({"error": "Email parameter is required"}, status=400)

    client = connect_to_mongodb()
    if not client:
        return JsonResponse({"error": "Failed to connect to MongoDB"}, status=500)

    db = client['test']
    users_collection = db['users']
    user = users_collection.find_one({"email": email})

    if user:
        food_items = user.get('foodItems', [])
        if not food_items:
            return JsonResponse({"error": "No food items found for this user"}, status=404)

        ingredients = transform_food_items(food_items)
        recipes = generate_recipes_from_ingredients(ingredients)
        return JsonResponse({"recipes": recipes}, safe=False, status=200)

    return JsonResponse({"error": "User not found"}, status=404)


@csrf_exempt
def send_recipes(request):
    if request.method in ['GET', 'POST']:
        # Retrieve the email from the request parameters, query params, or JSON body
        if request.method == 'POST':
            if request.content_type == 'application/json':
                try:
                    data = json.loads(request.body)
                    email = data.get('email')
                except json.JSONDecodeError:
                    email = None
            else:
                email = request.POST.get('email')
        else:
            email = request.GET.get('email')

        if not email:
            return JsonResponse({"error": "Email parameter is required"}, status=400)

        # Create a new request-like object for fetch_and_generate_recipes
        class CustomRequest:
            def __init__(self, post_data):
                self.POST = post_data
                self.method = 'POST'  # Set method to POST

        # Mimic a POST dictionary for custom_request
        post_data = {'email': email}
        custom_request = CustomRequest(post_data)

        # Call fetch_and_generate_recipes with the custom request
        recipes_response = fetch_and_generate_recipes(custom_request)

        # Check if there was an error in generating recipes
        if recipes_response.status_code != 200:
            return recipes_response

        # Retrieve generated recipes data
        # Use content instead of .json()
        recipes_data = json.loads(recipes_response.content)

        # Send the generated recipes to the NGROK_URL
        headers = {'Content-Type': 'application/json'}
        try:
            response = requests.post(
                NGROK_URL.rstrip('/') + '/',  # Ensure trailing slash
                json=recipes_data,
                headers=headers
            )

            if response.status_code == 200:
                return JsonResponse({'status': 'success', 'data': response.json()})
            else:
                return JsonResponse({
                    'status': 'error',
                    'message': f'Failed to send data: Status {response.status_code}',
                    'response_content': response.content.decode('utf-8')
                }, status=500)
        except requests.exceptions.RequestException as e:
            return JsonResponse({
                'status': 'error',
                'message': f'Request failed: {str(e)}'
            }, status=500)
    else:
        return JsonResponse({
            'status': 'error',
            'message': f'Method {request.method} not allowed'
        }, status=405)


@csrf_exempt
def receive_recipes(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            return JsonResponse({
                'status': 'success',
                'received_data': data
            })
        except json.JSONDecodeError:
            return JsonResponse({
                'status': 'error',
                'message': 'Invalid JSON data'
            }, status=400)
    return JsonResponse({
        'status': 'error',
        'message': 'Method not allowed'
    }, status=405)
