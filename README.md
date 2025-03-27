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

## Testing It Out

Want to try the Gemini integration without deploying everything?

```bash
cd src/ai
pip install -r requirements.txt
python gemini_test.py
```

Or simulate processing security findings locally:

```bash
cd src
python simulate_finding.py
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