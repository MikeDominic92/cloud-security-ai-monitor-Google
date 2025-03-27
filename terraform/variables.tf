variable "gcp_project_id" {
  description = "The GCP Project ID where resources will be deployed."
  type        = string
  # No default value - this should be provided explicitly when running Terraform.
}

variable "gcp_region" {
  description = "The GCP region for deploying resources."
  type        = string
  default     = "us-central1" # You can change this default if needed
}