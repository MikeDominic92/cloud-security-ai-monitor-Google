terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # Use a recent stable version
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

# Resource definitions will be added here later (e.g., Pub/Sub topics, Cloud Functions)