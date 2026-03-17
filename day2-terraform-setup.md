Step-by-Step Guide to Setting Up Terraform, AWS CLI, and My AWS Environment

Introduction

Today I completed the full setup for Terraform and AWS as part of my 30-Day Terraform Challenge. My goal was to create a secure, fully functional environment ready for deploying real cloud infrastructure.

1. Terraform Installation

I installed the latest Terraform version and verified it with:

terraform version

Terraform allows me to define infrastructure as code, making deployments repeatable, safe, and version-controlled.

2. AWS CLI Setup

I installed AWS CLI v2 and configured it using my dedicated IAM user (terraform-user):

aws configure

Set default region to us-east-1

I avoided using root credentials for security

Using an IAM user ensures my environment is secure and follows AWS best practices.

3. AWS Security & Budget

Enabled MFA on my root account

Created a $3/month budget with alerts at 80%

Even on free tier, this protects against accidental charges and strengthens account security.

4. VS Code Extensions

Installed:

HashiCorp Terraform – for syntax highlighting and auto-completion

AWS Toolkit – to interact with AWS directly from VS Code

These extensions make working with Terraform and AWS faster and easier.

5. Key Takeaways

Terraform uses IAM user credentials, not root, for safe operations

Proper setup avoids configuration errors and ensures a repeatable, secure environment

Budget alerts and MFA are small steps with big impact on security and cost control

Conclusion

With Terraform, AWS CLI, IAM user, MFA, budget alerts, and VS Code configured, my environment is professional-grade and ready for real deployments.

I’m excited to start building infrastructure confidently, knowing my setup is secure and fully functional.
