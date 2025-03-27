#!/usr/bin/env pwsh
# Cleanup script to remove all GCP resources created by this project

# Function to confirm before proceeding
function Confirm-Action {
    param (
        [string]$Message = "Are you sure you want to continue?"
    )
    
    $confirmation = Read-Host "$Message [y/N]"
    if ($confirmation -ne "y") {
        Write-Host "Operation cancelled."
        exit 0
    }
}

# Get the project ID from the argument or prompt the user
$PROJECT_ID = $args[0]
if (-not $PROJECT_ID) {
    $PROJECT_ID = Read-Host "Enter your GCP project ID"
}

Write-Host "⚠️ WARNING: This script will PERMANENTLY DELETE resources from your GCP project: $PROJECT_ID ⚠️" -ForegroundColor Red
Write-Host "Resources that will be deleted:" -ForegroundColor Yellow
Write-Host "- Cloud Function: scc-findings-processor" -ForegroundColor Yellow
Write-Host "- Pub/Sub topic and subscription: scc-notifications-topic" -ForegroundColor Yellow
Write-Host "- Storage bucket: security-ai-monitor-function-bucket" -ForegroundColor Yellow
Write-Host "- Secret Manager secret: gemini-api-key" -ForegroundColor Yellow
Write-Host "- IAM role bindings for the service account" -ForegroundColor Yellow

Confirm-Action "Are you ABSOLUTELY SURE you want to permanently delete these resources? Type 'y' to confirm"

# Use Terraform to destroy resources first if terraform exists
if (Test-Path -Path "./terraform") {
    Write-Host "Running Terraform destroy..." -ForegroundColor Cyan
    Push-Location -Path "./terraform"
    & terraform destroy -var="gcp_project_id=$PROJECT_ID" -auto-approve
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform destroy failed. Continuing with manual cleanup..." -ForegroundColor Red
    }
    Pop-Location
}

# Manual cleanup in case Terraform doesn't clean everything

# Delete the Cloud Function
Write-Host "Deleting Cloud Function..." -ForegroundColor Cyan
gcloud functions delete scc-findings-processor --project=$PROJECT_ID --region=us-central1 --quiet

# Delete the Pub/Sub topic and subscription
Write-Host "Deleting Pub/Sub resources..." -ForegroundColor Cyan
gcloud pubsub subscriptions delete scc-notifications-subscription --project=$PROJECT_ID --quiet
gcloud pubsub topics delete scc-notifications-topic --project=$PROJECT_ID --quiet

# Delete the Storage bucket
Write-Host "Deleting Storage bucket..." -ForegroundColor Cyan
gcloud storage rm gs://security-ai-monitor-function-bucket-$PROJECT_ID/* --recursive --quiet
gcloud storage rm gs://security-ai-monitor-function-bucket-$PROJECT_ID --quiet

# Delete the Secret Manager secret
Write-Host "Deleting Secret Manager secret..." -ForegroundColor Cyan
gcloud secrets delete gemini-api-key --project=$PROJECT_ID --quiet

# Delete the service account
Write-Host "Deleting service account..." -ForegroundColor Cyan
gcloud iam service-accounts delete security-monitor@$PROJECT_ID.iam.gserviceaccount.com --project=$PROJECT_ID --quiet

Write-Host "Cleanup completed!" -ForegroundColor Green
Write-Host "Note: Security Command Center settings may need to be manually removed from the GCP console." -ForegroundColor Yellow
