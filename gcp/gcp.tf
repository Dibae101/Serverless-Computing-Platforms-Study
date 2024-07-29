# Initialize the provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Variables
variable "project_id" {}
variable "region" {}

# Step 1: Create a Google Cloud Function
resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project_id}-function-bucket"
  location = var.region
}

resource "google_cloudfunctions_function" "function" {
  name        = "my-function"
  description = "My Cloud Function"
  runtime     = "nodejs14"  # Change this to your desired runtime
  entry_point = "helloWorld"
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = "function-source.zip"
  trigger_http          = true

  https_trigger_security_level = "SECURE_ALWAYS"

  available_memory_mb   = 128
  timeout               = 60
  service_account_email = google_service_account.function_service_account.email

  environment_variables = {
    CLIENT_ID     = var.client_id
    CLIENT_SECRET = var.client_secret
  }
}

# Step 2: Set Up IAM Roles
resource "google_service_account" "function_service_account" {
  account_id   = "function-sa"
  display_name = "Function Service Account"
}

resource "google_project_iam_member" "invoker" {
  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.function_service_account.email}"
}

# Step 3: Configure OAuth 2.0
# The OAuth 2.0 setup should be done manually in the Google Cloud Console, as it involves configuring consent screens and redirect URIs.
# However, you can set the credentials as environment variables in the function.

# Step 4: Enable Logging and Monitoring with Stackdriver
resource "google_logging_project_sink" "function_logs" {
  name        = "function-logs"
  destination = "logging.googleapis.com/projects/${var.project_id}/sinks/my-sink"
  filter      = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${google_cloudfunctions_function.function.name}\""
}

resource "google_logging_project_sink" "cloud_function_logging" {
  name        = "cloud-function-logging"
  destination = "logging.googleapis.com/projects/${var.project_id}/sinks/function-logs"
}

resource "google_monitoring_alert_policy" "function_alert_policy" {
  display_name = "Function Error Alert"
  combiner     = "OR"
  combiner     = "OR"

  conditions {
    display_name = "Function Error Rate"
    condition_threshold {
      filter          = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.label.\"status\"=\"error\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.ema
  combiner = "OR"
il_notification.name]

  combiner = "OR"
}

resource "google_monitoring_notification_channel" "email_notification" {
  display_name = "Email Notification Channel"
  type         = "email"
  labels = {
    email_address = "your-email@example.com"
  }
}

# Variables for Client ID and Secret
variable "client_id" {}
variable "client_secret" {}

# Step 5: Configure Data Encryption with Google Cloud KMS
resource "google_kms_key_ring" "function_key_ring" {
  name     = "function-key-ring"
  location = var.region
}

resource "google_kms_crypto_key" "function_crypto_key" {
  name     = "function-crypto-key"
  key_ring = google_kms_key_ring.function_key_ring.id
}

# Grant the service account access to the KMS key
resource "google_kms_crypto_key_iam_binding" "function_kms_binding" {
  crypto_key_id = google_kms_crypto_key.function_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = [
    "serviceAccount:${google_service_account.function_service_account.email}"
  ]
}

# Ensure TLS is enforced
resource "google_compute_ssl_certificate" "tls_cert" {
  name_prefix  = "tls-cert"
  description  = "TLS certificate for secure communication"
  private_key  = file("path/to/private_key.pem")
  certificate  = file("path/to/certificate.pem")
  project      = var.project_id
}

output "cloud_function_url" {
  value = google_cloudfunctions_function.function.https_trigger_url
}