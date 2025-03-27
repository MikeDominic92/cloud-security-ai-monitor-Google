# Contributing to GCP AI Security Monitor

Thanks for your interest in improving this project! This document outlines how to contribute to the GCP AI Security Monitor project.

## How to Contribute

### Reporting Issues

Found a bug or have a feature request? Open an issue describing:
1. What you wanted to do
2. What happened instead
3. Steps to reproduce (for bugs)

### Code Contributions
1. Fork the repository
2. Create a branch for your changes
3. Make your changes
4. Run tests locally
5. Submit a pull request

## Development Setup
1. Clone your fork
2. Install dependencies
   - Python 3.9+
   - Terraform 1.x
   - Google Cloud SDK
3. Set up your local environment variables:
```bash
cp .env.example .env
# Edit .env with your own values
```
## Code Style
- Python: Follow PEP 8
- Terraform: Use `terraform fmt` to format HCL files
- Git commits: Use conventional commits format

## Testing
Before submitting PRs, make sure to test:
1. Local simulation with `simulate_finding.py`
2. Terraform validation with `terraform validate`

## Security
- Never commit API keys or credentials
- Always use Secret Manager for sensitive data
- Verify IAM permissions follow least privilege principle

## License
By contributing, you agree that your contributions will be licensed under the project's MIT License.
