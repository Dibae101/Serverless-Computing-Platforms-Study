#This is a initial script to run, as AWS forces to change password on first login, this script will help to change password and get JWT token

import boto3
from botocore.exceptions import ClientError

def initiate_auth(username, password, user_pool_id, client_id, region):
    client = boto3.client('cognito-idp', region_name=region)
    
    try:
        response = client.initiate_auth(
            ClientId=client_id,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': username,
                'PASSWORD': password,
            }
        )
        return response
    except client.exceptions.UserNotFoundException:
        print("User not found.")
        return None
    except client.exceptions.NotAuthorizedException:
        print("Incorrect password.")
        return None
    except client.exceptions.PasswordResetRequiredException:
        print("Password reset required.")
        return None
    except ClientError as e:
        print(f"ClientError: {e}")
        return None

def respond_to_auth_challenge(username, new_password, user_pool_id, client_id, region, session):
    client = boto3.client('cognito-idp', region_name=region)
    
    try:
        response = client.respond_to_auth_challenge(
            ClientId=client_id,
            ChallengeName='NEW_PASSWORD_REQUIRED',
            ChallengeResponses={
                'USERNAME': username,
                'NEW_PASSWORD': new_password,
            },
            Session=session
        )
        return response
    except ClientError as e:
        print(f"ClientError: {e}")
        return None

def get_jwt_token(username, password, new_password, user_pool_id, client_id, region):
    auth_response = initiate_auth(username, password, user_pool_id, client_id, region)
    
    if auth_response is None:
        print("Authentication failed.")
        return None
    
    if 'ChallengeName' in auth_response and auth_response['ChallengeName'] == 'NEW_PASSWORD_REQUIRED':
        session = auth_response['Session']
        challenge_response = respond_to_auth_challenge(username, new_password, user_pool_id, client_id, region, session)
        if challenge_response:
            return challenge_response['AuthenticationResult']['IdToken']
    
    return auth_response['AuthenticationResult']['IdToken']

username = 'darshan'
password = 'Test3663#^^#'
new_password = 'Dibae3663#^^#'
user_pool_id = 'us-east-1_c73cVBoKI'
client_id = '4fpn2kf3e9a918gi00qndtcut3'
region = 'us-east-1'

token = get_jwt_token(username, password, new_password, user_pool_id, client_id, region)
if token:
    print("JWT Token:", token)
else:
    print("Failed to retrieve JWT token.")