#!/usr/bin/env python3
"""
Security Finding Simulator
--------------------------
This script simulates a Security Command Center finding and processes it using
the same Cloud Function code that would run in GCP, but locally.
"""

import json
import os
import sys
import logging
from datetime import datetime

# Add the Cloud Function directory to the path so we can import its code
sys.path.append(os.path.join(os.path.dirname(__file__), 'functions/security_findings_processor'))

# Import the Cloud Function code
try:
    from main import get_gemini_analysis
except ImportError as e:
    print(f"Error importing Cloud Function code: {e}")
    print("Make sure you've installed the required dependencies:")
    print("pip install -r src/functions/security_findings_processor/requirements.txt")
    sys.exit(1)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Sample security findings for testing
SAMPLE_FINDINGS = {
    "public_bucket": {
        "name": "organizations/123456789/sources/5678/findings/finding-uuid-1234-5678-abcd",
        "parent": "organizations/123456789/sources/5678",
        "resourceName": "//storage.googleapis.com/projects/test-project/buckets/vulnerable-bucket",
        "state": "ACTIVE",
        "category": "PUBLIC_BUCKET_ACL",
        "externalUri": "https://console.cloud.google.com/storage/browser/vulnerable-bucket",
        "sourceProperties": {
            "ReactivationCount": 0,
            "ExceptionInstructions": "Add the security mark \"allow_public_bucket_acl\" to the asset with a value of \"true\" to prevent this finding from being activated again.",
            "SeverityLevel": "High",
            "Recommendation": "To make objects accessible through IAM only, ensure none of your objects are accessible globally. Go to the permissions tab and select the bucket, then select EDIT PERMISSIONS and remove any values with the entity User and name \"allUsers\" or \"allAuthenticatedUsers\".",
            "ProjectId": "test-project",
            "AssetCreationTime": "2025-01-15T10:12:30.000Z",
            "ScanRunId": "2025-03-27T10:23:30.00Z",
            "Finding Class": "MISCONFIGURATION",
            "Explanation": "This bucket's Access Control List (ACL) configuration grants global access to its resources."
        },
        "securityMarks": {},
        "eventTime": "2025-03-27T14:23:30Z",
        "createTime": "2025-03-27T14:23:30Z",
        "severity": "HIGH",
        "description": "Storage bucket vulnerable-bucket is globally accessible to the public"
    },
    "sql_injection": {
        "name": "organizations/123456789/sources/5678/findings/finding-uuid-5678-1234-efgh",
        "parent": "organizations/123456789/sources/5678",
        "resourceName": "//compute.googleapis.com/projects/test-project/zones/us-central1-a/instances/web-server-01",
        "state": "ACTIVE",
        "category": "APPLICATION_SQL_INJECTION",
        "externalUri": "https://console.cloud.google.com/compute/instancesDetail/zones/us-central1-a/instances/web-server-01",
        "sourceProperties": {
            "ReactivationCount": 2,
            "SeverityLevel": "Critical",
            "Recommendation": "Update your application to use parameterized queries or prepared statements. Implement proper input validation and sanitization.",
            "ProjectId": "test-project",
            "AttackVector": "Web Application",
            "ScanRunId": "2025-03-27T09:15:30.00Z",
            "Finding Class": "VULNERABILITY",
            "Explanation": "Web application is vulnerable to SQL injection attacks through the search parameter."
        },
        "securityMarks": {},
        "eventTime": "2025-03-27T13:15:30Z",
        "createTime": "2025-03-27T13:15:30Z",
        "severity": "CRITICAL",
        "description": "SQL injection vulnerability detected in web application on web-server-01"
    },
    "weak_credentials": {
        "name": "organizations/123456789/sources/5678/findings/finding-uuid-9012-3456-ijkl",
        "parent": "organizations/123456789/sources/5678",
        "resourceName": "//iam.googleapis.com/projects/test-project/serviceAccounts/test-sa@test-project.iam.gserviceaccount.com",
        "state": "ACTIVE",
        "category": "WEAK_CREDENTIALS",
        "externalUri": "https://console.cloud.google.com/iam-admin/serviceaccounts/details/test-sa@test-project.iam.gserviceaccount.com",
        "sourceProperties": {
            "ReactivationCount": 0,
            "SeverityLevel": "High",
            "Recommendation": "Rotate the service account key immediately and implement a key rotation policy.",
            "ProjectId": "test-project",
            "KeyAge": "365",
            "ScanRunId": "2025-03-27T08:45:30.00Z",
            "Finding Class": "MISCONFIGURATION",
            "Explanation": "Service account key has not been rotated in over 365 days."
        },
        "securityMarks": {},
        "eventTime": "2025-03-27T12:45:30Z",
        "createTime": "2025-03-27T12:45:30Z",
        "severity": "HIGH",
        "description": "Service account key for test-sa@test-project.iam.gserviceaccount.com has not been rotated in over a year"
    }
}

def simulate_finding(finding_type):
    """
    Simulate processing a security finding locally.
    
    Args:
        finding_type: Type of finding to simulate (public_bucket, sql_injection, weak_credentials)
    """
    if finding_type not in SAMPLE_FINDINGS:
        logger.error(f"Unknown finding type: {finding_type}")
        logger.info(f"Available finding types: {', '.join(SAMPLE_FINDINGS.keys())}")
        return
    
    finding = SAMPLE_FINDINGS[finding_type]
    
    logger.info(f"Simulating processing of {finding_type} finding")
    logger.info(f"Finding details: {finding['description']}")
    logger.info(f"Severity: {finding['severity']}")
    
    logger.info("Sending to Gemini for analysis...")
    analysis = get_gemini_analysis(finding)
    
    if "error" in analysis:
        logger.error(f"Error in analysis: {analysis['error']}")
    else:
        logger.info("Analysis completed successfully!")
        logger.info("\n===== GEMINI AI SECURITY ASSESSMENT =====\n")
        logger.info(analysis["ai_analysis"])
    
    # Save the analysis to a file
    output_dir = os.path.join(os.path.dirname(__file__), 'analysis_results')
    os.makedirs(output_dir, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = os.path.join(output_dir, f"{finding_type}_analysis_{timestamp}.json")
    
    with open(output_file, 'w') as f:
        json.dump(analysis, f, indent=2)
    
    logger.info(f"Analysis saved to {output_file}")

if __name__ == "__main__":
    print("\n===== GCP AI Security Monitor - Local Simulator =====\n")
    print("This tool simulates processing security findings using Gemini AI")
    print("Available finding types:")
    for i, finding_type in enumerate(SAMPLE_FINDINGS.keys(), 1):
        print(f"  {i}. {finding_type}")
    
    try:
        choice = input("\nEnter the number of the finding type to simulate (or 'q' to quit): ")
        if choice.lower() == 'q':
            sys.exit(0)
        
        choice = int(choice)
        if 1 <= choice <= len(SAMPLE_FINDINGS):
            finding_type = list(SAMPLE_FINDINGS.keys())[choice - 1]
            simulate_finding(finding_type)
        else:
            print(f"Invalid choice. Please enter a number between 1 and {len(SAMPLE_FINDINGS)}.")
    except ValueError:
        print("Invalid input. Please enter a number or 'q'.")
    except KeyboardInterrupt:
        print("\nSimulation cancelled.")
        sys.exit(0)
