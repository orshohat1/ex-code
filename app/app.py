from flask import Flask, request, jsonify
from datetime import datetime
from pymongo import MongoClient
from azure.storage.blob import BlobServiceClient
from azure.identity import AzureCliCredential
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

app = Flask(__name__)

# Define the Key Vault URL
KEY_VAULT_URL = "https://orkvejglixav.vault.azure.net/"
#credential = AzureCliCredential()
credential = DefaultAzureCredential()
secret_client = SecretClient(vault_url=KEY_VAULT_URL, credential=credential)

# Retrieve secrets from Azure Key Vault
app.config['SECRET_KEY'] = secret_client.get_secret("SECRET-KEY").value
app.config['MONGO_URI'] = secret_client.get_secret("MONGO-URI").value
app.config['AZURE_CONNECTION_STRING'] = secret_client.get_secret("S-CONNECTION-STRING").value

# Initialize MongoDB
try:
    app.mongo_client = MongoClient(app.config['MONGO_URI'])
    app.db = app.mongo_client['test']
    print("MongoDB connection successful")
except Exception as e:
    print(f"MongoDB connection error: {e}")


# Initialize Azure Blob Storage client
try:
    blob_service_client = BlobServiceClient.from_connection_string(app.config['AZURE_CONNECTION_STRING'])
    container_name = 'logs'
    container_client = blob_service_client.get_container_client(container_name)
    
    # Function to create a blob if it doesn't exist
    def create_blob_if_not_exists(blob_name):
        try:
            blob_client = container_client.get_blob_client(blob_name)
            if not blob_client.exists():
                blob_client.upload_blob(b'', overwrite=True)
                print(f"Blob {blob_name} created successfully")
        except Exception as e:
            print(f"Error creating blob: {e}")

    # Function to append logs to a blob
    def append_log_to_blob(blob_name, log_message):
        try:
            blob_client = container_client.get_blob_client(blob_name)
            if not blob_client.exists():
                blob_client.upload_blob(b'', overwrite=True)
            blob_data = blob_client.download_blob().readall()
            updated_data = blob_data + log_message.encode('utf-8') + b'\n'
            blob_client.upload_blob(updated_data, overwrite=True)
            print(f"Logged to blob: {blob_name}")
        except Exception as e:
            print(f"Error appending to blob: {e}")

except Exception as e:
    print(f"Azure Blob Storage connection error: {e}")


# Parsing the input time to datetime format (HH:MM)
def parse_time(time_str):
    try:
        time_str = time_str.replace(':', '')  

        if len(time_str) == 1:
            time_str = f'0{time_str}:00'

        elif len(time_str) == 2:
            time_str = f'{time_str}:00'

        elif len(time_str) == 3:
            time_str = f'0{time_str[0]}:{time_str[1:]}'

        elif len(time_str) == 4:
            time_str = f'{time_str[:2]}:{time_str[2:]}'

        elif len(time_str) == 5 and time_str[2] == ':':
            pass
        else:
            raise ValueError("Invalid time format")

        time_obj = datetime.strptime(time_str, '%H:%M').time()

        if not (datetime.strptime('00:00', '%H:%M').time() <= time_obj <= datetime.strptime('23:59', '%H:%M').time()):
            raise ValueError(f"Invalid hour '{time_str}'. Make sure you enter valid hours - 00:00 to 23:59.")
        
        return time_obj
    except ValueError as e:
        return str(e) 

@app.route('/rest', methods=['GET'])
def restaurant_recommendation():
    query = request.args.get('query', '').lower()
    request_log = f"Request: {request.method} {request.url} {request.args}"

    try:
        if len(query) == 0: 
            log = {"restaurantRecommendation": "query is empty"}
            append_log_to_blob('app_logs.txt', request_log)
            append_log_to_blob('app_logs.txt', str(log))
            return jsonify({"restaurantRecommendation": "query is empty"})

        open_start = open_end = open_time = closing_time = None
        curTime = datetime.now().time()

        if ' between ' in query:
            parts = query.split(' between ', 1)[1]
            for separator in [' and ', ' to ', '-']:
                if separator in parts:
                    open_start_str, open_end_str = [p.strip() for p in parts.split(separator, 1)]
                    open_start = parse_time(open_start_str)
                    open_end = parse_time(open_end_str)
                    if isinstance(open_start, str):  
                        append_log_to_blob('app_logs.txt', request_log)
                        return jsonify({"restaurantRecommendation": open_start})
                    if isinstance(open_end, str):
                        append_log_to_blob('app_logs.txt', request_log)
                        return jsonify({"restaurantRecommendation": open_end})
                    break

        elif ' closes at ' in query or ' closing at ' in query:
            closing_time_str = query.split(' closes at ', 1)[1] if ' closes at ' in query else query.split(' closing at ', 1)[1]
            closing_time = parse_time(closing_time_str.strip())
            if isinstance(closing_time, str):
                append_log_to_blob('app_logs.txt', request_log)
                return jsonify({"restaurantRecommendation": closing_time})

        elif ' opens at ' in query or ' opening at ' in query:
            open_time_str = query.split(' opens at ', 1)[1] if ' opens at ' in query else query.split(' opening at ', 1)[1]
            open_time = parse_time(open_time_str.strip())
            if isinstance(open_time, str):
                append_log_to_blob('app_logs.txt', request_log)
                return jsonify({"restaurantRecommendation": open_time})

        vegetarian = 'yes' if 'vegetarian' in query else 'no'
        style = ''
        if 'italian' in query:
            style = 'Italian'
        elif 'steakhouse' in query:
            style = 'Steakhouse'
        elif 'asian' in query:
            style = 'Asian'
        elif 'mediterranean' in query:
            style = 'Mediterranean'

        query_filter = {
            'vegetarian': vegetarian,
        }

        if style:
            query_filter['style'] = style
        
        if open_start and open_end:
            query_filter['openHour'] = {'$lte': open_start.strftime('%H:%M')}
            query_filter['closeHour'] = {'$gte': open_end.strftime('%H:%M')}
        
        if closing_time:
            query_filter['closeHour'] = {'$gte': closing_time.strftime('%H:%M')}
        
        if open_time:
            query_filter['openHour'] = {'$lte': open_time.strftime('%H:%M')}

        if not open_start and not open_end and not closing_time and not open_time:
            query_filter['openHour'] = {'$lte': curTime.strftime('%H:%M')}
            query_filter['closeHour'] = {'$gte': curTime.strftime('%H:%M')}

        restaurants = list(app.db.restaurants.find(query_filter, {'_id': 0}))
                        
        if not restaurants:
            log = {"restaurantRecommendation": "There are no results."}
            append_log_to_blob('app_logs.txt', request_log)
            append_log_to_blob('app_logs.txt', str(log))
            return jsonify({"restaurantRecommendation": "There are no results."})
        
        log = {"restaurantRecommendation": restaurants}
        append_log_to_blob('app_logs.txt', request_log)
        append_log_to_blob('app_logs.txt', str(log))
        return jsonify({"restaurantRecommendation": restaurants})
    
    except Exception as e:
        error_message = f"An error occurred: {e}"
        append_log_to_blob('app_logs.txt', request_log)
        append_log_to_blob('app_logs.txt', error_message)
        return jsonify({"restaurantRecommendation": error_message})

if __name__ == '__main__':
    create_blob_if_not_exists('app_logs.txt')
    print("succesfull")
    app.run(debug=True)