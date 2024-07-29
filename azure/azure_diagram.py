from diagrams import Diagram, Cluster
from diagrams.azure.compute import FunctionApps
from diagrams.azure.network import ApplicationGateway
from diagrams.azure.security import KeyVaults
from diagrams.azure.identity import ActiveDirectory
from diagrams.azure.analytics import LogAnalyticsWorkspaces
from diagrams.azure.devops import ApplicationInsights
from diagrams.azure.storage import StorageAccounts

with Diagram("Azure Functions with Security and Compliance", show=False):
    with Cluster("Azure Resource Group"):
        storage = StorageAccounts("Storage Account")
        insights = ApplicationInsights("App Insights")
        log_analytics = LogAnalyticsWorkspaces("Log Analytics Workspace")
        key_vault = KeyVaults("Key Vault")
        function_app = FunctionApps("Function App")
        ad_app = ActiveDirectory("Azure AD App")

        function_app >> insights
        function_app >> log_analytics
        function_app >> key_vault
        ad_app >> function_app
        function_app >> storage