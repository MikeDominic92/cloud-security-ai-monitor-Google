# GCP AI Security Monitor

I built this project to create a smart security monitoring system for Google Cloud Platform environments. It uses Gemini AI to analyze security findings and provide insights that go beyond basic alerting.

## Project Goals and Outcomes

This project was created with several specific objectives:

1. **Enhance Security Visibility**: Transform raw security findings into actionable intelligence using AI
2. **Reduce Response Time**: Accelerate threat analysis through automated AI assessment
3. **Improve Remediation Quality**: Provide detailed, context-aware mitigation recommendations
4. **Demonstrate Modern SecOps**: Showcase how GenAI can transform cloud security operations

The end result is a production-ready system that brings AI-powered security analysis to any GCP environment, potentially reducing security incident resolution time by up to 60%.

## Technical Architecture

![Architecture Overview](./docs/architecture.png)

The system uses a serverless, event-driven architecture:

1. Security Command Center detects and generates security findings
2. Findings are published to a Pub/Sub topic
3. Cloud Function is triggered by the Pub/Sub message
4. Function processes the finding and sends it to Gemini AI
5. Gemini AI analyzes the finding and provides enhanced insights
6. Analysis results are logged for review and further automation

All infrastructure is defined as code using Terraform, ensuring repeatability and consistency across deployments.

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

1. **Authenticate with Google Cloud**

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project security-ai-monitor-2025
```

1. **Enable required APIs**

```bash
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable securitycenter.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable aiplatform.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

1. **Set up the Gemini API key in Secret Manager**

This script securely stores your API key in GCP Secret Manager:

```bash
./setup_secrets.ps1 security-ai-monitor-2025
```

1. **Deploy infrastructure with Terraform**

```bash
cd terraform
terraform init
terraform apply -var="gcp_project_id=security-ai-monitor-2025"
```

1. **Configure Security Command Center notifications**

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
4. Returns structured analysis with:
   * Severity validation
   * Impact assessment
   * Remediation steps
   * Related threat patterns

## Project Impact & Business Value

This solution delivers tangible security benefits:

1. **Faster Incident Response**: Reduce analysis time from hours to seconds
2. **Improved Decision Making**: Better context leads to more effective prioritization
3. **Cost Reduction**: Automation reduces security team workload
4. **Enhanced Compliance**: Better documentation of security incidents and responses

For large enterprises, this could translate to millions in savings through:

* Reduced breach risk
* Lower security operations costs
* Faster incident resolution
* More effective resource allocation

## Cleanup When Done

To avoid incurring GCP costs after testing, run the cleanup script:

```bash
./cleanup.ps1 security-ai-monitor-2025
```

This will remove all resources created by the project.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.