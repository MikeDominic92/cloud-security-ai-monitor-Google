import os
import json
import base64
import logging
import google.cloud.logging
import vertexai
from vertexai.generative_models import GenerativeModel, Content
import functions_framework
from google.cloud import pubsub_v1

# Initialize logging
logging_client = google.cloud.logging.Client()
logging_client.setup_logging()

# Get configuration from environment variables
PROJECT_ID = os.environ.get("PROJECT_ID")
LOCATION = os.environ.get("LOCATION")

# Get API key from environment variable
# For security in production, use Secret Manager instead of environment variables
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
if not GEMINI_API_KEY:
    logging.warning("No GEMINI_API_KEY found, AI analysis will be limited")

# Set up the Vertex AI client with configurations
vertexai.init(project=PROJECT_ID, location=LOCATION)

# Configure the generative model
MODEL_NAME = "gemini-2.0-flash"

def get_gemini_analysis(finding_data):
    """
    Process security finding data using Gemini 2.0 Flash model to get analysis and recommendations.
    
    Args:
        finding_data: The security finding data from Security Command Center
        
    Returns:
        dict: Analysis results containing severity assessment, impact analysis, and recommendations
    """
    try:
        # Create the model
        model = GenerativeModel(MODEL_NAME)
        
        # Format the finding data for the prompt
        finding_name = finding_data.get("name", "Unknown")
        finding_category = finding_data.get("category", "Unknown")
        finding_severity = finding_data.get("severity", "Unknown")
        finding_description = finding_data.get("description", "No description provided")
        resource_name = finding_data.get("resourceName", "Unknown")
        
        # Build comprehensive prompt for Gemini
        prompt = f"""
        Analyze this Google Cloud Security Command Center finding and provide a detailed security assessment:
        
        # FINDING DETAILS
        - Name: {finding_name}
        - Category: {finding_category}
        - Severity: {finding_severity}
        - Description: {finding_description}
        - Resource: {resource_name}
        
        # REQUESTED ANALYSIS
        1. SEVERITY VALIDATION: Assess if the assigned severity is appropriate. If not, suggest a more appropriate severity level with justification.
        
        2. IMPACT ANALYSIS: What could be the potential impact of this security issue? Consider data sensitivity, system criticality, and potential attack vectors.
        
        3. MITIGATION RECOMMENDATIONS: Provide specific remediation steps that would address this security finding in Google Cloud.
        
        4. RELATED THREATS: Are there related threats or attack patterns that could exploit this vulnerability? List any CWE, MITRE ATT&CK, or other security framework references.
        
        Format your response as a structured security assessment report.
        """

        # Generate content with Gemini
        response = model.generate_content(prompt)
        
        # Process the response
        if response and response.text:
            # Extract key information from the response
            analysis_text = response.text
            
            # Return structured analysis
            return {
                "finding_data": {
                    "name": finding_name,
                    "category": finding_category,
                    "severity": finding_severity,
                    "resource": resource_name
                },
                "ai_analysis": analysis_text,
                "timestamp": finding_data.get("createTime", "")
            }
        else:
            logging.error("Empty response from Gemini model")
            return {
                "error": "Failed to generate analysis",
                "finding": finding_name
            }
            
    except Exception as e:
        logging.error(f"Error during Gemini analysis: {str(e)}")
        return {
            "error": str(e),
            "finding": finding_data.get("name", "Unknown")
        }

@functions_framework.cloud_event
def process_scc_finding(cloud_event):
    """
    Cloud Function triggered by a Pub/Sub message when a new Security Command Center finding is published.
    
    Args:
        cloud_event: The Cloud Event containing the Pub/Sub message
    """
    try:
        # Extract message data from the cloud event
        pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode("utf-8")
        message_data = json.loads(pubsub_message)
        
        # Extract finding data
        finding = message_data.get("finding", {})
        
        # Log receipt of the finding
        logging.info(f"Received security finding: {finding.get('name', 'Unknown')}")
        
        # Only process high or critical severity findings
        severity = finding.get("severity", "").lower()
        if severity not in ["high", "critical"]:
            logging.info(f"Skipping {severity} severity finding")
            return
        
        # Get AI analysis from Gemini
        analysis = get_gemini_analysis(finding)
        
        # Log the analysis result
        logging.info(f"Generated AI analysis for finding: {finding.get('name', 'Unknown')}")
        
        # Here you would typically:
        # 1. Store the analysis in a database
        # 2. Trigger a notification or alert
        # 3. Initiate an automated remediation if appropriate
        
        # For demonstration, we'll just log the analysis result
        if "error" not in analysis:
            logging.info(f"Analysis complete: {json.dumps(analysis)}")
        else:
            logging.error(f"Analysis failed: {json.dumps(analysis)}")
            
    except Exception as e:
        logging.error(f"Error processing finding: {str(e)}")
        raise
