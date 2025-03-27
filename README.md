# GCP AI Security Monitor & Response System

This project is building an autonomous system to monitor a Google Cloud Platform (GCP) environment for security threats. It uses AI and machine learning not just to detect issues, but also to predict potential threats and automatically trigger responses.

The main idea is to create something more advanced than a standard SIEM. By integrating predictive analytics and automated remediation, the system aims to proactively handle security incidents in a complex cloud setup.

## Project Goal

I'm building this to demonstrate practical skills in modern cloud security operations, specifically:

* Applying AI/ML for smarter threat detection and prediction.
* Automating incident response in a GCP environment.
* Working with various GCP security services and tools.

This project is designed to showcase the kind of proactive, automated security approach relevant for a SOC Analyst role.

## Tech Stack

* **Cloud:** Google Cloud Platform (GCP)
* **AI/ML:** Google AI Platform (Vertex AI) for model training (anomaly detection, threat prediction).
* **Automation:** Google Cloud Functions for executing response actions.
* **Security Data:** GCP Security Command Center for ingesting alerts.
* **Orchestration:** Shuffle Automation (or potentially Google Chronicle SOAR) for managing response workflows.
* **Language:** Python
* **IaC:** Terraform to manage the GCP infrastructure.

## Setup Instructions

### Prerequisites

* Google Cloud Platform account with billing enabled
* Terraform installed locally
* Python 3.9+ installed
* Google Cloud SDK installed

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/cloud-security-ai-monitor.git
cd cloud-security-ai-monitor
```

### Step 2: Configure Google Cloud Authentication

```bash
# Authenticate with Google Cloud
gcloud auth login

# Set up application default credentials
gcloud auth application-default login

# Set your project ID
gcloud config set project security-ai-monitor-2025
```

### Step 3: Enable Required APIs

```bash
# Enable required APIs
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable securitycenter.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable aiplatform.googleapis.com
```

### Step 4: Deploy Infrastructure with Terraform

```bash
cd terraform
terraform init
terraform apply -var="gcp_project_id=security-ai-monitor-2025"
```

### Step 5: Configure Security Command Center Notifications

After deploying the infrastructure, you need to configure Security Command Center to send findings to the Pub/Sub topic:

1. Go to Security Command Center in the Google Cloud Console
2. Navigate to Settings > Notifications
3. Create a new notification with the following settings:
   * Name: `ai-monitor-notifications`
   * Pubsub topic: Use the topic name from Terraform output
   * Filter: `severity="HIGH" OR severity="CRITICAL"`

## Usage

Once deployed, the system will automatically:

1. Receive Security Command Center findings via Pub/Sub
2. Process the findings using Cloud Functions
3. Analyze the security findings with Gemini AI
4. Generate detailed security assessments including:
   * Severity validation
   * Impact analysis
   * Mitigation recommendations
   * Related threats and attack patterns

## Testing

To test the Gemini API integration without deploying to GCP:

```bash
cd src/ai
pip install -r requirements.txt
python gemini_test.py
```

To simulate processing security findings locally:

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
├── terraform/             # Infrastructure as Code definitions
├── src/
│   ├── functions/         # Cloud Function code
│   │   └── security_findings_processor/
│   │       ├── main.py    # Function implementation
│   │       └── requirements.txt
│   └── ai/                # AI model testing scripts
│       ├── gemini_test.py
│       └── requirements.txt
└── setup_gcp_environment.ps1  # GCP setup script
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Current Progress

* [x] Infrastructure definition with Terraform
* [x] Cloud Function implementation for processing findings
* [x] Gemini API integration for AI analysis
* [x] Testing scripts and simulation environment
* [ ] Production deployment