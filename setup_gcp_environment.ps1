# GCP AI Security Monitor Setup Script
# This script helps set up your Google Cloud environment for the AI Security Monitor project

# Configuration - Update these values
$PROJECT_ID = "security-ai-monitor-2025"  # Replace with your actual project ID
$PROJECT_NAME = "AI Security Monitor"  # You can change this name
$SERVICE_ACCOUNT_NAME = "ai-security-monitor-sa"
$REGION = "us-central1"  # Default region, you can change this

Write-Host "=== GCP AI Security Monitor Setup ===" -ForegroundColor Cyan

# Step 1: Authenticate with Google Cloud
Write-Host "`n[Step 1] Authenticating with Google Cloud..." -ForegroundColor Green
gcloud auth login

# Step 2: Create or select a project
Write-Host "`n[Step 2] Creating/selecting project..." -ForegroundColor Green
$PROJECT_EXISTS = gcloud projects list --filter="PROJECT_ID=$PROJECT_ID" --format="value(PROJECT_ID)"

if ($PROJECT_EXISTS) {
    Write-Host "Project $PROJECT_ID already exists. Using existing project." -ForegroundColor Yellow
    gcloud config set project $PROJECT_ID
} else {
    Write-Host "Creating new project: $PROJECT_NAME (ID: $PROJECT_ID)" -ForegroundColor Green
    gcloud projects create $PROJECT_ID --name="$PROJECT_NAME"
    gcloud config set project $PROJECT_ID
}

# Step 3: Enable required APIs
Write-Host "`n[Step 3] Enabling required APIs..." -ForegroundColor Green
$APIS = @(
    "pubsub.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "securitycenter.googleapis.com",
    "logging.googleapis.com",
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "aiplatform.googleapis.com",
    "iam.googleapis.com"
)

foreach ($API in $APIS) {
    Write-Host "Enabling $API..."
    gcloud services enable $API --project=$PROJECT_ID
}

# Step 4: Create service account
Write-Host "`n[Step 4] Creating service account..." -ForegroundColor Green
$SA_EXISTS = gcloud iam service-accounts list --project=$PROJECT_ID --filter="EMAIL:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --format="value(EMAIL)"

if ($SA_EXISTS) {
    Write-Host "Service account $SERVICE_ACCOUNT_NAME already exists." -ForegroundColor Yellow
} else {
    Write-Host "Creating service account: $SERVICE_ACCOUNT_NAME"
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME `
        --display-name="AI Security Monitor Service Account" `
        --project=$PROJECT_ID
}

# Step 5: Grant roles to the service account
Write-Host "`n[Step 5] Granting roles to service account..." -ForegroundColor Green
$ROLES = @(
    "roles/pubsub.editor",
    "roles/cloudfunctions.developer",
    "roles/iam.serviceAccountUser",
    "roles/securitycenter.adminViewer",
    "roles/logging.logWriter",
    "roles/storage.admin",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/aiplatform.user"
)

foreach ($ROLE in $ROLES) {
    Write-Host "Granting $ROLE..."
    gcloud projects add-iam-policy-binding $PROJECT_ID `
        --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" `
        --role="$ROLE"
}

# Step 6: Create and download service account key
Write-Host "`n[Step 6] Creating service account key..." -ForegroundColor Green
$KEY_PATH = "$PSScriptRoot\credentials\$SERVICE_ACCOUNT_NAME-key.json"
gcloud iam service-accounts keys create $KEY_PATH `
    --iam-account="$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"

# Step 7: Set environment variable for authentication
Write-Host "`n[Step 7] Setting GOOGLE_APPLICATION_CREDENTIALS environment variable..." -ForegroundColor Green
$env:GOOGLE_APPLICATION_CREDENTIALS = $KEY_PATH
[Environment]::SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", $KEY_PATH, "User")

# Step 8: Set default region for gcloud
Write-Host "`n[Step 8] Setting default region to $REGION..." -ForegroundColor Green
gcloud config set compute/region $REGION

Write-Host "`n=== Setup Complete! ===" -ForegroundColor Cyan
Write-Host "Your GCP environment has been configured with the following:" -ForegroundColor White
Write-Host "- Project ID: $PROJECT_ID" -ForegroundColor White
Write-Host "- Service Account: $SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" -ForegroundColor White
Write-Host "- Service Account Key: $KEY_PATH" -ForegroundColor White
Write-Host "- Required APIs enabled" -ForegroundColor White
Write-Host "- Required roles assigned" -ForegroundColor White
Write-Host "- Default region set to $REGION" -ForegroundColor White
Write-Host "`nNext steps:" -ForegroundColor Green
Write-Host "1. Update the terraform/variables.tf file with your Project ID" -ForegroundColor White
Write-Host "2. Run Terraform to deploy the infrastructure:" -ForegroundColor White
Write-Host "   cd terraform" -ForegroundColor White
Write-Host "   terraform init" -ForegroundColor White
Write-Host "   terraform apply -var=\"gcp_project_id=$PROJECT_ID\" -var=\"storage_bucket_name=$PROJECT_ID-security-monitor\"" -ForegroundColor White
