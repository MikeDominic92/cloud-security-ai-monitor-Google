# GCP AI Security Monitor & Response System

This project is building an autonomous system to monitor a Google Cloud Platform (GCP) environment for security threats. It uses AI and machine learning not just to detect issues, but also to predict potential threats and automatically trigger responses.

The main idea is to create something more advanced than a standard SIEM. By integrating predictive analytics and automated remediation, the system aims to proactively handle security incidents in a complex cloud setup.

## Project Goal

I'm building this to demonstrate practical skills in modern cloud security operations, specifically:
*   Applying AI/ML for smarter threat detection and prediction.
*   Automating incident response in a GCP environment.
*   Working with various GCP security services and tools.

This project is designed to showcase the kind of proactive, automated security approach relevant for a SOC Analyst role.

## Tech Stack

*   **Cloud:** Google Cloud Platform (GCP)
*   **AI/ML:** Google AI Platform (Vertex AI) for model training (anomaly detection, threat prediction).
*   **Automation:** Google Cloud Functions for executing response actions.
*   **Security Data:** GCP Security Command Center for ingesting alerts.
*   **Orchestration:** Shuffle Automation (or potentially Google Chronicle SOAR) for managing response workflows.
*   **Language:** Python
*   **IaC (Planned):** Terraform or Cloud Deployment Manager to manage the GCP infrastructure.