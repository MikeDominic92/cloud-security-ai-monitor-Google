variable "gcp_project_id" {
  description = "The GCP Project ID where resources will be deployed."
  type        = string
  default     = "security-ai-monitor-2025"
}

variable "gcp_region" {
  description = "The GCP region for deploying resources."
  type        = string
  default     = "us-central1" # You can change this default if needed
}

variable "service_account_id" {
  description = "ID of the service account used for deploying and managing resources"
  type        = string
  default     = "ai-security-monitor-sa"
}

variable "scc_notification_name" {
  description = "Name of the Security Command Center notification configuration"
  type        = string
  default     = "scc-high-severity-findings"
}

variable "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic for receiving security findings"
  type        = string
  default     = "scc-findings-topic"
}

variable "storage_bucket_name" {
  description = "Name of the Cloud Storage bucket for function code and artifacts"
  type        = string
  default     = "security-monitor"
}

variable "ai_model_name" {
  description = "The Vertex AI model to use for analysis"
  type        = string
  default     = "gemini-2.0-flash"
}