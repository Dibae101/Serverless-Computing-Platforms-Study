import boto3
from warrant_lite import WarrantLite
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_jwt_token(username, password, user_pool_id, client_id, region):
    client = boto3.client('cognito-idp', region_name=region)
    wl = WarrantLite(
        username=username,
        password=password,
        pool_id=user_pool_id,
        client_id=client_id,
        client=client,
    )
    tokens = wl.authenticate_user()
    logger.info(f"Tokens received: {tokens}")  # Log the structure of tokens

    # Assuming the structure of tokens is {'AuthenticationResult': {'IdToken': 'value'}}
    # Adjust the key access based on the actual structure logged above
    try:
        id_token = tokens['AuthenticationResult']['IdToken']
    except KeyError:
        logger.error("KeyError accessing IdToken. Check the structure of 'tokens'.")
        raise

    return id_token

# Replace with your Cognito details
username = 'darshan'
password = 'Test3663#^^#'
user_pool_id = 'us-east-1_c73cVBoKI'
client_id = '4fpn2kf3e9a918gi00qndtcut3'
region = 'us-east-1'

# Attempt to get the token
try:
    token = get_jwt_token(username, password, user_pool_id, client_id, region)
    print("JWT Token:", token)
except Exception as e:
    logger.error(f"Failed to get JWT token: {e}")