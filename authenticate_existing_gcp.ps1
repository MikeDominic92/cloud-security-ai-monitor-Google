# GCP Authentication Script (Using Existing SDK)
# This script helps you authenticate with Google Cloud using your existing SDK installation

Write-Host "=== Google Cloud Authentication Helper ===" -ForegroundColor Cyan
Write-Host "This script will guide you through authenticating with Google Cloud." -ForegroundColor White

# Check for gcloud in the path
$gcloudCommand = Get-Command gcloud -ErrorAction SilentlyContinue

if (-not $gcloudCommand) {
    # Try to find gcloud in the default installation location
    $gcloudPath = "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
    
    if (Test-Path $gcloudPath) {
        Write-Host "`nFound Google Cloud SDK at: $gcloudPath" -ForegroundColor Green
        # Add to path for this session
        $env:Path = "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin;$env:Path"
        $gcloudCommand = $gcloudPath
    } else {
        Write-Host "`nCould not find gcloud command. Please make sure Google Cloud SDK is installed and in your PATH." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`nFound Google Cloud SDK in PATH: $($gcloudCommand.Source)" -ForegroundColor Green
}

# Check if user is authenticated
Write-Host "`n[Step 1] Checking authentication status..." -ForegroundColor Green
$authStatus = & gcloud auth list --format="value(account)" 2>$null

if (-not $authStatus) {
    Write-Host "`nYou are not authenticated with Google Cloud." -ForegroundColor Yellow
    Write-Host "Starting authentication process..." -ForegroundColor Green
    
    # Start authentication
    & gcloud auth login
} else {
    Write-Host "`nYou are already authenticated as: $authStatus" -ForegroundColor Green
}

# List available projects
Write-Host "`n[Step 2] Listing your Google Cloud projects..." -ForegroundColor Green
& gcloud projects list

# Set up project
$projectId = "security-ai-monitor-2025"  # Our default project ID
Write-Host "`n[Step 3] Setting up project: $projectId" -ForegroundColor Green

# Check if project exists
$projectExists = & gcloud projects list --filter="PROJECT_ID=$projectId" --format="value(PROJECT_ID)"

if ($projectExists) {
    Write-Host "Project $projectId already exists. Using existing project." -ForegroundColor Yellow
    & gcloud config set project $projectId
} else {
    Write-Host "Creating new project: $projectId" -ForegroundColor Green
    & gcloud projects create $projectId --name="AI Security Monitor"
    & gcloud config set project $projectId
}

# Enable required APIs
Write-Host "`n[Step 4] Enabling required APIs..." -ForegroundColor Green
$apis = @(
    "pubsub.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "securitycenter.googleapis.com",
    "logging.googleapis.com",
    "storage.googleapis.com",
    "aiplatform.googleapis.com",
    "iam.googleapis.com"
)

foreach ($api in $apis) {
    Write-Host "Enabling $api..."
    & gcloud services enable $api --project=$projectId
}

# Create service account
$serviceAccountName = "ai-security-monitor-sa"
Write-Host "`n[Step 5] Creating service account: $serviceAccountName" -ForegroundColor Green

$saExists = & gcloud iam service-accounts list --project=$projectId --filter="EMAIL:$serviceAccountName@$projectId.iam.gserviceaccount.com" --format="value(EMAIL)"

if ($saExists) {
    Write-Host "Service account $serviceAccountName already exists." -ForegroundColor Yellow
} else {
    & gcloud iam service-accounts create $serviceAccountName `
        --display-name="AI Security Monitor Service Account" `
        --project=$projectId
}

# Grant roles to service account
Write-Host "`n[Step 6] Granting roles to service account..." -ForegroundColor Green
$roles = @(
    "roles/pubsub.editor",
    "roles/cloudfunctions.developer",
    "roles/iam.serviceAccountUser",
    "roles/securitycenter.adminViewer",
    "roles/logging.logWriter",
    "roles/storage.admin",
    "roles/aiplatform.user"
)

foreach ($role in $roles) {
    Write-Host "Granting $role..."
    & gcloud projects add-iam-policy-binding $projectId `
        --member="serviceAccount:$serviceAccountName@$projectId.iam.gserviceaccount.com" `
        --role="$role"
}

# Create and download service account key
Write-Host "`n[Step 7] Creating service account key..." -ForegroundColor Green
$keyPath = "$PSScriptRoot\credentials\$serviceAccountName-key.json"
& gcloud iam service-accounts keys create $keyPath `
    --iam-account="$serviceAccountName@$projectId.iam.gserviceaccount.com"

# Set environment variable for authentication
Write-Host "`n[Step 8] Setting GOOGLE_APPLICATION_CREDENTIALS environment variable..." -ForegroundColor Green
$env:GOOGLE_APPLICATION_CREDENTIALS = $keyPath
[Environment]::SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", $keyPath, "User")

Write-Host "`n=== Authentication Complete! ===" -ForegroundColor Cyan
Write-Host "Your GCP environment has been configured with the following:" -ForegroundColor White
Write-Host "- Project ID: $projectId" -ForegroundColor White
Write-Host "- Service Account: $serviceAccountName@$projectId.iam.gserviceaccount.com" -ForegroundColor White
Write-Host "- Service Account Key: $keyPath" -ForegroundColor White
Write-Host "- Required APIs enabled" -ForegroundColor White
Write-Host "- Required roles assigned" -ForegroundColor White
Write-Host "`nNext steps:" -ForegroundColor Green
Write-Host "1. Run Terraform to deploy the infrastructure:" -ForegroundColor White
Write-Host "   cd terraform" -ForegroundColor White
Write-Host "   terraform init" -ForegroundColor White
Write-Host "   terraform apply" -ForegroundColor White
