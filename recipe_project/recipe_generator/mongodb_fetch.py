# recipe-generator/mongodb_fetch.py

import os
import json
from pathlib import Path
from dotenv import load_dotenv
from pymongo import MongoClient
from bson import json_util
import requests
from views import generate_prompt, extract_json_from_text
import google.generativeai as genai
from django.conf import settings

# Get the path to the recipe-project directory (parent of current directory)
BASE_DIR = Path(__file__).resolve().parent.parent

# Load environment variables from .env file in the project root
load_dotenv(os.path.join(BASE_DIR, '.env'))

# API endpoints
SEND_RECIPE_URL = 'https://64ee-103-104-226-58.ngrok-free.app/recipe/send-user-recipe'
RECEIVE_RECIPE_URL = 'https://64ee-103-104-226-58.ngrok-free.app/recipe/receive-user-recipe'


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


def check_recipe_status():
    """
    Check if recipes are available at the receive endpoint
    """
    try:
        print(f"\nChecking recipe status at: {RECEIVE_RECIPE_URL}")
        response = requests.get(RECEIVE_RECIPE_URL)

        print(f"Status Check Response Status: {response.status_code}")
        print(f"Status Check Response Content: {response.text}")

        return response.status_code == 200

    except Exception as e:
        print(f"Error checking recipe status: {str(e)}")
        return False


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


# API endpoints
SEND_RECIPE_URL = 'https://64ee-103-104-226-58.ngrok-free.app/recipe/send-user-recipe'


def send_recipes_to_api(recipes, user_email):
    """
    Send generated recipes to the API endpoint
    """
    try:
        # Prepare the payload with generated recipes and user email
        payload = {
            "email": user_email,
            "recipes": recipes
        }

        # Send POST request to the API
        headers = {'Content-Type': 'application/json'}
        response = requests.post(
            SEND_RECIPE_URL, json=payload, headers=headers)

        if response.status_code == 200:
            print("Successfully sent recipes to API")
            return True
        else:
            print(f"Failed to send recipes. Status code: {
                  response.status_code}")
            return False

    except Exception as e:
        print(f"Error sending recipes to API: {str(e)}")
        return False


def fetch_and_generate_recipes():
    client = connect_to_mongodb()
    if not client:
        return

    try:
        db = client['test']
        users_collection = db['users']
        user = users_collection.find_one(
            {"email": "shaanagarwalofficial@gmail.com"})

        if user:
            user_email = user.get('email')
            food_items = user.get('foodItems', [])
            if not food_items:
                print("No food items found for this user")
                return

            ingredients = transform_food_items(food_items)
            recipes = generate_recipes_from_ingredients(ingredients)

            if recipes:
                # Send generated recipes to the Django API endpoint
                if send_recipes_to_api(recipes, user_email):
                    print("Recipes successfully processed and sent to the API.")
                else:
                    print("Failed to send recipes to the API.")
            else:
                print("Failed to generate recipes")
        else:
            print("User not found")

    except Exception as e:
        print(f"Error processing data: {str(e)}")

    finally:
        client.close()
        print("\nMongoDB connection closed")


if __name__ == "__main__":
    fetch_and_generate_recipes()
