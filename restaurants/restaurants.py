from pymongo import MongoClient
import json
import os

# Initialize MongoDB connection
mongo_uri = os.getenv('MONGODB_URI')
client = MongoClient(mongo_uri)
db = client['test']
collection = db['restaurants']


# Required fields to create new restaurant
required_fields = {"name", "style", "address", "openHour", "closeHour", "vegetarian"}

# Load restaurants from JSON file
with open('restaurants.json', 'r') as file:
    restaurants = json.load(file)

# Insert only new restaurant
def insert_restaurants(restaurants):
    for restaurant in restaurants:
        
        # Check if all required fields are present
        missing_fields = required_fields - restaurant.keys()
        extra_fields = restaurant.keys() - required_fields

        if missing_fields or extra_fields:
            print(f"Invalid restaurant (missing or extra fields): {restaurant}")
            if missing_fields:
                print(f"Missing fields: {missing_fields}")
            if extra_fields:
                print(f"Extra fields: {extra_fields}")
            continue
        
        existing_res = collection.find_one({"address": restaurant["address"]})
        if existing_res is None:
            collection.insert_one(restaurant)
            print(f"Inserted restaurant: {restaurant}")

insert_restaurants(restaurants)