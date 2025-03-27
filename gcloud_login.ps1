# GCloud Login Helper Script
# This script helps you sign in to Google Cloud

# Find gcloud executable
$gcloudPaths = @(
    "C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd",
    "C:\Program Files\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd",
    "C:\Users\$env:USERNAME\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd",
    "C:\Google Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
)

$gcloudPath = $null
foreach ($path in $gcloudPaths) {
    if (Test-Path $path) {
        $gcloudPath = $path
        break
    }
}

if ($gcloudPath) {
    Write-Host "Found gcloud at: $gcloudPath"
    Write-Host "Launching Google Cloud authentication..."
    
    # Run gcloud auth login
    & $gcloudPath auth login
    
    # After login, also set up application default credentials
    Write-Host "`nSetting up application default credentials..."
    & $gcloudPath auth application-default login
    
    Write-Host "`nAuthentication complete! You can now run Terraform commands."
} else {
    Write-Host "Could not find gcloud executable. Please provide the path to gcloud.cmd or gcloud.exe:"
    $customPath = Read-Host
    
    if (Test-Path $customPath) {
        Write-Host "Using custom path: $customPath"
        & $customPath auth login
        & $customPath auth application-default login
    } else {
        Write-Host "Invalid path. Please make sure Google Cloud SDK is installed."
    }
}
