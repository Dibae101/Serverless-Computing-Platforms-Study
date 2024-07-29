import json
import requests

def lambda_handler(event, context):
    base_url = "https://we5wdftw39.execute-api.us-east-1.amazonaws.com/test-stage"
    path = "/secure-data"
    url = base_url + path
    headers = {
        "Authorization": "Bearer PLACE_TOKEN_HERE"  # Replace with actual token
    }
    
    try:
        # Make the GET request
        response = requests.get(url, headers=headers)
        response.raise_for_status()  # Raise an exception for HTTP errors
        
        # Process the response
        result = {
            "statusCode": response.status_code,
            "headers": dict(response.headers),
            "body": response.text[:500]  # Limiting body size for example
        }
        
    except requests.exceptions.RequestException as e:
        # Handle request exceptions
        result = {
            "statusCode": 500,
            "body": f"An error occurred: {e}"
        }
    
    return result