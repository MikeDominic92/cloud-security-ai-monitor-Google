# GCP Authentication Script
# This script helps you authenticate with Google Cloud

Write-Host "=== Google Cloud Authentication Helper ===" -ForegroundColor Cyan
Write-Host "This script will guide you through authenticating with Google Cloud." -ForegroundColor White

# Check if Google Cloud SDK is installed
$gcloudPath = "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
$gcloudInstalled = Test-Path $gcloudPath

if (-not $gcloudInstalled) {
    Write-Host "`n[Step 1] Google Cloud SDK not found. Downloading installer..." -ForegroundColor Yellow
    
    # Download the installer
    $installerPath = "$env:USERPROFILE\Downloads\GoogleCloudSDKInstaller.exe"
    Invoke-WebRequest -Uri "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe" -OutFile $installerPath
    
    # Run the installer
    Write-Host "`nStarting Google Cloud SDK installer..." -ForegroundColor Green
    Write-Host "Please complete the installation process in the window that opens." -ForegroundColor Yellow
    Write-Host "IMPORTANT: Make sure to check 'Add gcloud to PATH' during installation." -ForegroundColor Red
    
    Start-Process -FilePath $installerPath -Wait
    
    Write-Host "`nAfter installation completes, please restart this script." -ForegroundColor Green
    exit
}

# If we get here, gcloud is installed
Write-Host "`n[Step 2] Google Cloud SDK is installed." -ForegroundColor Green

# Add gcloud to the current session's PATH if not already there
$env:Path = "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin;$env:Path"

# Check if user is authenticated
Write-Host "`n[Step 3] Checking authentication status..." -ForegroundColor Green
$authStatus = & $gcloudPath auth list --format="value(account)" 2>$null

if (-not $authStatus) {
    Write-Host "`nYou are not authenticated with Google Cloud." -ForegroundColor Yellow
    Write-Host "Starting authentication process..." -ForegroundColor Green
    
    # Start authentication
    & $gcloudPath auth login
} else {
    Write-Host "`nYou are already authenticated as: $authStatus" -ForegroundColor Green
}

# List available projects
Write-Host "`n[Step 4] Listing your Google Cloud projects..." -ForegroundColor Green
& $gcloudPath projects list

# Set up project
$projectId = "security-ai-monitor-2025"  # Our default project ID
Write-Host "`n[Step 5] Setting up project: $projectId" -ForegroundColor Green

# Check if project exists
$projectExists = & $gcloudPath projects list --filter="PROJECT_ID=$projectId" --format="value(PROJECT_ID)"

if ($projectExists) {
    Write-Host "Project $projectId already exists. Using existing project." -ForegroundColor Yellow
    & $gcloudPath config set project $projectId
} else {
    Write-Host "Creating new project: $projectId" -ForegroundColor Green
    & $gcloudPath projects create $projectId --name="AI Security Monitor"
    & $gcloudPath config set project $projectId
}

# Enable required APIs
Write-Host "`n[Step 6] Enabling required APIs..." -ForegroundColor Green
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
    & $gcloudPath services enable $api --project=$projectId
}

# Create service account
$serviceAccountName = "ai-security-monitor-sa"
Write-Host "`n[Step 7] Creating service account: $serviceAccountName" -ForegroundColor Green

$saExists = & $gcloudPath iam service-accounts list --project=$projectId --filter="EMAIL:$serviceAccountName@$projectId.iam.gserviceaccount.com" --format="value(EMAIL)"

if ($saExists) {
    Write-Host "Service account $serviceAccountName already exists." -ForegroundColor Yellow
} else {
    & $gcloudPath iam service-accounts create $serviceAccountName `
        --display-name="AI Security Monitor Service Account" `
        --project=$projectId
}

# Grant roles to service account
Write-Host "`n[Step 8] Granting roles to service account..." -ForegroundColor Green
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
    & $gcloudPath projects add-iam-policy-binding $projectId `
        --member="serviceAccount:$serviceAccountName@$projectId.iam.gserviceaccount.com" `
        --role="$role"
}

# Create and download service account key
Write-Host "`n[Step 9] Creating service account key..." -ForegroundColor Green
$keyPath = "$PSScriptRoot\credentials\$serviceAccountName-key.json"
& $gcloudPath iam service-accounts keys create $keyPath `
    --iam-account="$serviceAccountName@$projectId.iam.gserviceaccount.com"

# Set environment variable for authentication
Write-Host "`n[Step 10] Setting GOOGLE_APPLICATION_CREDENTIALS environment variable..." -ForegroundColor Green
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
