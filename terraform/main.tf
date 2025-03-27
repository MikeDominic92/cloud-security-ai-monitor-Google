terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # Use a recent stable version
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2" # Use a recent stable version
    }
  }
  required_version = ">= 1.0" # Specify minimum Terraform version
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  # Credentials will typically be handled via Application Default Credentials (ADC)
  # or by setting the GOOGLE_APPLICATION_CREDENTIALS environment variable.
}

# Create a globally unique GCS bucket for function code and artifacts
resource "google_storage_bucket" "function_bucket" {
  name                        = "${var.gcp_project_id}-${var.storage_bucket_name}-bucket"
  location                    = var.gcp_region
  uniform_bucket_level_access = true
  force_destroy               = true # Allow Terraform to destroy the bucket even if it contains objects
}

# Create a Pub/Sub topic to receive Security Command Center findings
resource "google_pubsub_topic" "scc_findings_topic" {
  name = var.pubsub_topic_name
}

# Create a subscription to process messages from the topic
resource "google_pubsub_subscription" "scc_findings_subscription" {
  name  = "${var.pubsub_topic_name}-subscription"
  topic = google_pubsub_topic.scc_findings_topic.name

  ack_deadline_seconds = 60 # Time to acknowledge the message

  # Configure message retention
  message_retention_duration = "604800s" # 7 days

  # Retry policy
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s" # Max of 10 minutes
  }
}

# IAM binding to allow the service account to publish to the topic
resource "google_pubsub_topic_iam_binding" "topic_publisher" {
  topic   = google_pubsub_topic.scc_findings_topic.name
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${var.service_account_id}@${var.gcp_project_id}.iam.gserviceaccount.com"]
}

# IAM binding to allow the service account to subscribe to the topic
resource "google_pubsub_subscription_iam_binding" "subscription_subscriber" {
  subscription = google_pubsub_subscription.scc_findings_subscription.name
  role         = "roles/pubsub.subscriber"
  members      = ["serviceAccount:${var.service_account_id}@${var.gcp_project_id}.iam.gserviceaccount.com"]
}

# Archive the Cloud Function source code
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "../src/functions/security_findings_processor"
  output_path = "function-source.zip"
}

# Upload the Cloud Function source code to GCS
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source-${data.archive_file.function_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_zip.output_path
}

# Deploy the Cloud Function
resource "google_cloudfunctions_function" "scc_findings_processor" {
  name        = "scc-findings-processor"
  description = "Processes Security Command Center findings using Gemini AI"
  runtime     = "python310"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_source.name

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.scc_findings_topic.name
  }

  entry_point = "process_scc_finding"

  environment_variables = {
    "PROJECT_ID" = var.gcp_project_id
    "LOCATION"   = "us-central1"
  }

  service_account_email = "${var.service_account_id}@${var.gcp_project_id}.iam.gserviceaccount.com"
}

# Add IAM role binding for the security findings processor Cloud Function
# Comment out this resource until proper permissions are available
/*
resource "google_project_iam_binding" "function_scc_viewer" {
  project = var.gcp_project_id
  role    = "roles/securitycenter.findingsViewer"
  
  members = [
    "serviceAccount:${var.service_account_id}@${var.gcp_project_id}.iam.gserviceaccount.com",
  ]
}
*/

# Output the Pub/Sub topic name for use in the Security Command Center notification configuration
output "pubsub_topic_name" {
  value       = google_pubsub_topic.scc_findings_topic.name
  description = "The name of the Pub/Sub topic to use in Security Command Center notification configuration"
}

output "service_account_email" {
  value       = "${var.service_account_id}@${var.gcp_project_id}.iam.gserviceaccount.com"
  description = "The email of the service account used for this project"
}

output "storage_bucket" {
  value       = google_storage_bucket.function_bucket.name
  description = "The name of the storage bucket for function code and artifacts"
}

# Add output for Cloud Function URL
output "function_url" {
  value       = google_cloudfunctions_function.scc_findings_processor.https_trigger_url
  description = "Cloud Function URL for manual testing"
}