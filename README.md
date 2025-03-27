# GCP AI Security Monitor

I built this project to create a smart security monitoring system for Google Cloud Platform environments. It uses Gemini AI to analyze security findings and provide insights that go beyond basic alerting.

## The Idea Behind This

Working in cloud security, I've noticed that standard monitoring tools often just tell you what happened without much context. This system tries to solve that by using AI to understand security findings, assess their severity, and suggest practical fixes.

The project combines GCP's Security Command Center with the Gemini 2.0 Flash model to create something that doesn't just detect issues but actually helps you understand and fix them.

## What It Does

When Security Command Center finds a potential issue, the system:

1. Captures the finding details through a Pub/Sub message
2. Processes it with a Cloud Function
3. Sends it to Gemini AI for analysis
4. Returns a comprehensive assessment including:
   * Validation of the severity level
   * Impact analysis
   * Specific remediation steps
   * Related threat patterns

## Tech I Used

* Google Cloud Platform services (Security Command Center, Pub/Sub, Cloud Functions)
* Gemini 2.0 Flash model for AI analysis
* Python for implementation
* Terraform for infrastructure as code

## Setting It Up

You'll need:

* A GCP account with billing
* Terraform installed locally
* Python 3.9+
* Google Cloud SDK

### Full Setup Process

1. **Clone the repo**

```bash
git clone https://github.com/MikeDominic92/cloud-security-ai-monitor-Google.git
cd cloud-security-ai-monitor-Google
```

2. **Authenticate with Google Cloud**

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project security-ai-monitor-2025
```

3. **Enable required APIs**

```bash
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable securitycenter.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable aiplatform.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

4. **Set up the Gemini API key in Secret Manager**

This script securely stores your API key in GCP Secret Manager:

```bash
./setup_secrets.ps1 security-ai-monitor-2025
```

5. **Deploy infrastructure with Terraform**

```bash
cd terraform
terraform init
terraform apply -var="gcp_project_id=security-ai-monitor-2025"
```

6. **Configure Security Command Center notifications**

After deployment, set up SCC to send findings to your Pub/Sub topic:

1. Go to Security Command Center in the console
2. Navigate to Settings > Notifications
3. Create a notification with:
   * Name: `ai-monitor-notifications`
   * Pubsub topic: Use the topic from Terraform output
   * Filter: `severity="HIGH" OR severity="CRITICAL"`

### Security Best Practices

This project follows security best practices by:

* Storing API keys in Secret Manager, not in code
* Using least-privilege service accounts
* Securing function invocation
* Encrypting data in transit and at rest

## Testing the Project

If you're evaluating this project, here are different ways to test it - from simplest to most comprehensive:

### Option 1: Quick Demo Without Deployment

Want to see the AI analysis without setting up GCP? Run the local simulator:

```bash
# Install dependencies
cd src/ai
pip install -r requirements.txt

# Set your API key as an environment variable
$env:GEMINI_API_KEY = "your_gemini_api_key"

# Run the test script
python gemini_test.py
```

You'll see a sample security finding analyzed by Gemini AI with severity validation, impact analysis, and remediation steps.

### Option 2: Simulate a Finding Locally

For a more complete test that simulates the Cloud Function processing:

```bash
# Install dependencies
cd src
pip install -r ../src/functions/security_findings_processor/requirements.txt

# Set your API key as an environment variable
$env:GEMINI_API_KEY = "your_gemini_api_key"

# Run the simulator
python simulate_finding.py
```

This runs the actual Cloud Function code locally against sample findings. Follow the prompts to select different test scenarios.

### Option 3: Full GCP Deployment Testing

After deployment, test the complete system:

1. **Manually trigger a message**:

```bash
# Create a sample finding message
$MESSAGE = @"
{
  "finding": {
    "name": "organizations/123456789/sources/5678/findings/test-finding-01",
    "parent": "organizations/123456789/sources/5678",
    "resourceName": "//storage.googleapis.com/projects/security-ai-monitor-2025/buckets/test-bucket",
    "state": "ACTIVE",
    "category": "PUBLIC_BUCKET_ACL",
    "severity": "HIGH",
    "description": "Test security finding for GCP AI Security Monitor",
    "sourceProperties": {
      "ReactivationCount": 0,
      "SeverityLevel": "High",
      "ProjectId": "security-ai-monitor-2025"
    },
    "createTime": "2025-03-27T14:23:30Z"
  }
}
"@

# Encode and publish to Pub/Sub
$ENCODED = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($MESSAGE))
gcloud pubsub topics publish scc-notifications-topic --message=$ENCODED --project=security-ai-monitor-2025
```

2. **Check the Cloud Function logs**:

```bash
gcloud functions logs read scc-findings-processor --limit=50 --project=security-ai-monitor-2025
```

You should see:
* "Received security finding: organizations/123456789/sources/5678/findings/test-finding-01"
* "Generated AI analysis for finding"
* The complete AI analysis content

3. **Create a real security finding**:

If you want to test with a real security finding:
* Create a public Cloud Storage bucket in your project
* Go to Security Command Center to see the finding
* Verify in logs that your function processed it

### What You'll See

When working correctly, the system:
1. Receives security findings from Security Command Center
2. Processes them using the Cloud Function
3. Analyzes them with Gemini 2.0 Flash
4. Generates a security assessment with:
   * Severity validation (Is the assigned severity appropriate?)
   * Impact analysis (What could be the consequences?)
   * Remediation steps (How to fix the issue)
   * Related threats (What attack patterns are associated?)

The output looks like this:

```plaintext
===== GEMINI AI SECURITY ASSESSMENT =====

SECURITY FINDING ANALYSIS
Finding: PUBLIC_BUCKET_ACL in vulnerable-bucket
Severity: HIGH

1. SEVERITY VALIDATION
The HIGH severity assigned is appropriate. Public storage buckets can expose sensitive data to anyone on the internet, creating significant security risk.

2. IMPACT ANALYSIS
* Unauthorized data access and potential data leakage
* Potential compliance violations (GDPR, HIPAA, etc.)
* Data tampering or poisoning attacks
* Reputational damage if sensitive information is exposed

3. MITIGATION RECOMMENDATIONS
* Immediately restrict bucket access to appropriate principals only
* Remove all "allUsers" and "allAuthenticatedUsers" permissions
* Implement proper IAM roles with least privilege
* Enable Cloud Audit Logs to monitor bucket access
* Consider using Object Versioning to recover from tampering

4. RELATED THREATS
CWE-284: Improper Access Control
MITRE ATT&CK: Initial Access (T1190)
OWASP Top 10: A5:2021 – Security Misconfiguration
```

## Architecture

The system architecture includes:

1. **Security Command Center** - Source of security findings
2. **Pub/Sub Topic** - Message queue for findings
3. **Cloud Function** - Processes findings and calls Gemini API
4. **Gemini API** - Analyzes findings and generates security assessments
5. **Cloud Storage** - Stores function code and deployment artifacts

## Security Note

This project includes an API key for demonstration purposes. In a production environment:

1. Store API keys in Secret Manager
2. Use service account authentication
3. Implement proper IAM roles and permissions
4. Enable audit logging

## Project Structure

```plaintext
cloud-security-ai-monitor/
├── terraform/             # Infrastructure code
├── src/
│   ├── functions/         # Cloud Function code
│   │   └── security_findings_processor/
│   │       ├── main.py    # Main function code
│   │       └── requirements.txt
│   └── ai/                # AI testing scripts
│       ├── gemini_test.py
│       └── requirements.txt
└── setup_gcp_environment.ps1  # Setup script
```

## Contributing

Got ideas? Feel free to submit a pull request!

## License

This project uses the MIT License - see the LICENSE file for details.

## Current Progress

* [x] Infrastructure definition with Terraform
* [x] Cloud Function implementation for processing findings
* [x] Gemini API integration for AI analysis
* [x] Testing scripts and simulation environment
* [ ] Production deployment