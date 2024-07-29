from diagrams import Diagram, Cluster, Edge
from diagrams.gcp.compute import Functions
from diagrams.gcp.security import KMS, IAP
from diagrams.gcp.operations import Monitoring as StackdriverMonitoring, Logging as StackdriverLogging
from diagrams.onprem.client import Users
from diagrams.generic.network import Firewall

with Diagram("Google Cloud Functions With Security and Compliance", show=False):

    with Cluster("Google Cloud"):
        # Users accessing the system
        users = Users("Users")

        # Cloud Function
        cloud_function = Functions("Cloud Function")

        # HTTP Trigger
        http_trigger = Firewall("HTTP Trigger")

        # OAuth 2.0 Configuration
        oauth2 = IAP("OAuth 2.0")

        # Cloud KMS for Encryption
        kms = KMS("Cloud KMS")

        # Monitoring and Logging
        monitoring = StackdriverMonitoring("Stackdriver Monitoring")
        logging = StackdriverLogging("Stackdriver Logging")

        # Define the connections
        users >> http_trigger >> cloud_function
        cloud_function >> oauth2
        cloud_function >> kms
        cloud_function >> monitoring
        cloud_function >> logging