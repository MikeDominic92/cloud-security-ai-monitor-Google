#!/usr/bin/env pwsh
# Script to set up Secret Manager secret for the Gemini API key

# Check if gcloud is available
if (-not (Get-Command "gcloud" -ErrorAction SilentlyContinue)) {
    Write-Error "Google Cloud SDK not found. Please install it and make sure it's in your PATH."
    exit 1
}

# Get the project ID from the argument or prompt the user
$PROJECT_ID = $args[0]
if (-not $PROJECT_ID) {
    $PROJECT_ID = Read-Host "Enter your GCP project ID"
}

# Get the API key from the user
$API_KEY = Read-Host "Enter your Gemini API key" -AsSecureString
$APIKEY_PLAIN = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($API_KEY)
)

Write-Host "Setting up Secret Manager..."

# Enable the Secret Manager API
gcloud services enable secretmanager.googleapis.com --project=$PROJECT_ID
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to enable Secret Manager API."
    exit 1
}

# Check if the secret already exists
$SECRET_EXISTS = $false
$SECRET_LIST = gcloud secrets list --filter="name:gemini-api-key" --project=$PROJECT_ID --format="value(name)"
if ($SECRET_LIST -eq "gemini-api-key") {
    $SECRET_EXISTS = $true
}

# Create or update the secret
if (-not $SECRET_EXISTS) {
    # Create the secret
    Write-Host "Creating secret 'gemini-api-key'..."
    gcloud secrets create gemini-api-key --project=$PROJECT_ID
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create secret."
        exit 1
    }
}

# Add the new version with the API key
Write-Host "Adding API key to secret..."
$APIKEY_PLAIN | gcloud secrets versions add gemini-api-key --data-file=- --project=$PROJECT_ID
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to add secret version."
    exit 1
}

# Grant the Cloud Function service account access to the secret
$SERVICE_ACCOUNT = "security-monitor@$PROJECT_ID.iam.gserviceaccount.com"
Write-Host "Granting access to service account $SERVICE_ACCOUNT..."
gcloud secrets add-iam-policy-binding gemini-api-key `
    --member="serviceAccount:$SERVICE_ACCOUNT" `
    --role="roles/secretmanager.secretAccessor" `
    --project=$PROJECT_ID
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to grant access to service account."
    exit 1
}

Write-Host "Secret setup complete! The Gemini API key is now stored securely in Secret Manager."
Write-Host "Your Cloud Function will be able to access it securely."
