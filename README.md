# 30-Day Terraform Challenge

A public documentation of my hands-on Terraform learning journey. Building real AWS infrastructure from scratch, one day at a time.

This is not a tutorial repo. It is a live record of what I built, what broke, and what I learned. Every entry is written from experience, not theory.

---

## Why I Started This

I wanted to move beyond watching videos and actually build infrastructure. The 30-Day Terraform Challenge gave me a structure to do that. Shipping something real every day and documenting it publicly.

By the end of 30 days the goal is to have gone from zero to building production-grade infrastructure on AWS using Infrastructure as Code.

---

## Progress

| Day | Topic | Key Concepts |
|-----|-------|-------------|
| Day 1 | [What is Infrastructure as Code and Why It Matters](day1.md) | IaC, Declarative vs Imperative, Why Terraform |
| Day 2 | [Setting Up Terraform, AWS CLI and My AWS Environment](day2.md) | Terraform install, AWS CLI, IAM user, MFA, Budget alerts |
| Day 3 | [Deploying My First Server with Terraform](day3.md) | EC2, Security Groups, User Data, Apache, terraform destroy |
| Day 4 | [Building a Highly Available Web App with Auto Scaling and Load Balancing](day4.md) | ASG, ALB, Launch Template, Target Group, DRY principle |
| Day 5 | [Managing High Traffic Applications with ALB and Terraform State](day5.md) | State management, State drift, Remote state, ALB deep dive |
| Day 6 | [Managing and Securing Terraform State](day6.md) | Remote state with S3, DynamoDB state locking, State migration, Versioning |
| Day 7 | [State Isolation: Workspaces vs File Layouts](day7.md) | Terraform workspaces, File layout isolation, terraform_remote_state, Multi-environment strategy |
| Days 8–30 | In progress | |

---

## What I Have Built So Far

**Single EC2 Web Server** — A fully functional web server on AWS provisioned entirely with Terraform. Custom security groups, Apache installed via user data, accessible via public IP.

**Highly Available Web Application** — Moved from a single server to a production-style architecture with an Auto Scaling Group maintaining minimum 2 instances, scaling to 5, behind an Application Load Balancer distributing traffic across multiple EC2 instances.

**Terraform State Experiments** — Explored how Terraform state works, what happens when you manually edit the state file, and how infrastructure drift is detected and reconciled.

---

## Architecture Evolution

```
Day 3:
User → Security Group → EC2 Instance

Day 4 & 5:
User → Application Load Balancer → Target Group → Auto Scaling Group → EC2 Instances (min 2, max 5)
```

---

## Key Concepts Covered

| Concept | Day Introduced |
|---------|---------------|
| Infrastructure as Code | Day 1 |
| Terraform CLI setup | Day 2 |
| Provider configuration | Day 3 |
| Resource blocks | Day 3 |
| Security Groups | Day 3 |
| User Data scripts | Day 3 |
| Launch Templates | Day 4 |
| Auto Scaling Groups | Day 4 |
| Application Load Balancer | Day 4 |
| DRY principle with variables | Day 4 |
| Terraform state management | Day 5 |
| State drift detection | Day 5 |
| Remote state concepts | Day 5 |
| S3 remote backend | Day 6 |
| DynamoDB state locking | Day 6 |
| State migration | Day 6 |
| Terraform workspaces | Day 7 |
| File layout isolation | Day 7 |
| terraform_remote_state | Day 7 |
| Multi-environment strategy | Day 7 |

---

## Terraform Workflow

Every project in this challenge follows the same lifecycle:

```bash
terraform init      # Initialise the working directory
terraform plan      # Preview changes before applying
terraform apply     # Create or update infrastructure
terraform destroy   # Clean up all resources after testing
```

Running `terraform destroy` after every project is a deliberate practice. It keeps costs at zero and reinforces the habit of treating infrastructure as disposable and reproducible.

---

## Tools and Stack

| Tool | Purpose |
|------|---------|
| Terraform | Infrastructure as Code |
| AWS EC2 | Compute instances |
| AWS ALB | Application Load Balancer |
| AWS Auto Scaling | Scalable instance management |
| AWS IAM | Secure access management |
| AWS VPC | Networking |
| VS Code | Editor with HashiCorp Terraform extension |
| AWS CLI | Command line access to AWS |

---

## Challenges and Fixes

Real mistakes from the challenge — documented so others do not make the same ones.

**t2.micro no longer free tier eligible** — Switched to t3.micro after reading the Terraform error output carefully.

**AWS authentication failure** — IAM access key had been deactivated. Reactivated and verified via AWS CLI before re-running Terraform.

**User data changes not reflecting** — Terraform does not re-run user data on existing instances. Fix was terraform destroy followed by terraform apply.

**Deprecated Launch Configuration** — AWS no longer supports Launch Configurations for new accounts. Switched to Launch Template which is the modern standard.

**Wrong target group attribute** — Used alb_target_group_arn instead of lb_target_group_arn. A small naming error that caused a pipeline failure and taught me to read Terraform docs carefully.

**State drift confusion** — Manually editing the state file does not change infrastructure. Terraform compares live infrastructure against code, not the state file directly.

---

## About This Challenge

This challenge is part of the EveOps 30-Day Terraform Challenge. A community-driven initiative to build real cloud infrastructure skills through hands-on daily practice.

---

## Author

**Grace Kihonge** — Cloud & DevOps Engineer based in Nairobi, Kenya.
Transitioning from IT Customer Support into Cloud & DevOps, building real infrastructure and documenting everything publicly.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/grace-kihonge-1354a9310/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Grace4549)
