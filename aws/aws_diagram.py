from diagrams import Diagram, Cluster
from diagrams.aws.compute import Lambda
from diagrams.aws.network import APIGateway
from diagrams.aws.security import IAM, Cognito
from diagrams.aws.management import Cloudtrail, Cloudwatch
from diagrams.aws.storage import S3
from diagrams.aws.security import KMS

with Diagram("AWS Lambda Functions with Security and Compliance", show=False):
    with Cluster("IAM"):
        lambda_role = IAM("Lambda Execution Role")
        lambda_policy = IAM("Lambda Basic Execution Policy")
    
    with Cluster("AWS KMS"):
        kms_key = KMS("KMS Key")

    lambda_function = Lambda("Test Lambda")
    lambda_function - lambda_role
    lambda_function - lambda_policy
    lambda_function - kms_key

    with Cluster("API Gateway"):
        api_gateway = APIGateway("REST API")
        resource = APIGateway("Resource: /test")
        method = APIGateway("GET Method")
        authorizer = Cognito("Cognito Authorizer")
        api_gateway >> resource >> method >> lambda_function
        api_gateway >> authorizer

    with Cluster("Cognito"):
        user_pool = Cognito("User Pool")
        app_client = Cognito("App Client")

    authorizer - user_pool
    authorizer - app_client

    with Cluster("CloudWatch"):
        cw_logs = Cloudwatch("Logs")
        cw_metrics = Cloudwatch("Metrics")
        lambda_function >> cw_logs
        api_gateway >> cw_metrics

    with Cluster("CloudTrail"):
        cloudtrail = Cloudtrail("CloudTrail")
        s3_bucket = S3("S3 Bucket for Logs")
        cloudtrail - s3_bucket
        api_gateway >> cloudtrail