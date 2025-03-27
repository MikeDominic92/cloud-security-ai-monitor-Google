#!/usr/bin/env python3
"""
Gemini API Integration Test Script
---------------------------------
This script tests the connection to Google's Vertex AI Generative API
using the Gemini 2.0 Flash model to analyze a sample security finding.
"""

import os
import json
import google.generativeai as genai
from datetime import datetime

# Set API key
GEMINI_API_KEY = "AIzaSyDtv9mid4t0_zj3OLl-UceA7SgKQjw5_RQ"  # API key provided by user
genai.configure(api_key=GEMINI_API_KEY)

# Sample security finding for testing
SAMPLE_FINDING = {
    "name": "organizations/123456789/sources/5678/findings/finding-uuid-1234-5678-abcd",
    "parent": "organizations/123456789/sources/5678",
    "resourceName": "//compute.googleapis.com/projects/test-project/zones/us-central1-a/instances/test-instance",
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
}

def test_gemini_integration():
    """Test the Gemini model with a sample security finding."""
    try:
        # Create the model - specifically using gemini-2.0-flash as requested
        model = genai.GenerativeModel('gemini-2.0-flash')
        
        # Format the finding data for the prompt
        finding_name = SAMPLE_FINDING.get("name", "Unknown")
        finding_category = SAMPLE_FINDING.get("category", "Unknown")
        finding_severity = SAMPLE_FINDING.get("severity", "Unknown")
        finding_description = SAMPLE_FINDING.get("description", "No description provided")
        resource_name = SAMPLE_FINDING.get("resourceName", "Unknown")
        
        # Build a prompt for Gemini
        prompt = f"""
        Analyze this Google Cloud Security Command Center finding and provide a detailed security assessment:
        
        # FINDING DETAILS
        - Name: {finding_name}
        - Category: {finding_category}
        - Severity: {finding_severity}
        - Description: {finding_description}
        - Resource: {resource_name}
        
        # REQUESTED ANALYSIS
        1. SEVERITY VALIDATION: Assess if the assigned severity is appropriate.
        2. IMPACT ANALYSIS: What could be the potential impact of this security issue?
        3. MITIGATION RECOMMENDATIONS: Provide specific remediation steps.
        4. RELATED THREATS: Are there related threats or attack patterns that could exploit this vulnerability?
        
        Format your response as a structured security assessment report.
        """

        # Generate content with Gemini
        response = model.generate_content(prompt)
        
        # Print the response
        print("\n===== GEMINI API TEST RESULTS =====\n")
        print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Model: gemini-2.0-flash")
        print(f"Status: {'SUCCESS - API is working!' if response.text else 'FAILED - Empty response'}")
        print("\n===== SAMPLE SECURITY ASSESSMENT =====\n")
        if response.text:
            print(response.text)
        else:
            print("No response received from Gemini API.")
        
        return True
        
    except Exception as e:
        print("\n===== GEMINI API TEST RESULTS =====\n")
        print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Model: gemini-2.0-flash")
        print(f"Status: FAILED - API error")
        print(f"Error: {str(e)}")
        return False

if __name__ == "__main__":
    print("Starting Gemini API integration test...")
    success = test_gemini_integration()
    if success:
        print("\nTest completed successfully! The Gemini API integration is working.")
    else:
        print("\nTest failed. Please check your API key and network connection.")
