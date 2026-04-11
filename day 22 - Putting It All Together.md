# Putting It All Together: Application and Infrastructure Workflows with Terraform

*Day 22 of the 30-Day Terraform Challenge*

22 Days, One Integrated Pipeline, and What I Actually Learned

## The Big Idea: Your Plan File Is a Docker Image

Here is the insight that reframed everything for me.

App teams figured this out years ago. You build a Docker image once. You test that exact image. You promote that exact image through staging and production. You never rebuild it. What was tested is what gets deployed.

Terraform has the same pattern. Most teams ignore it.

```bash
# Build the artifact once
terraform plan -out=ci.tfplan

# Promote that exact artifact
terraform apply ci.tfplan
```

The plan file is your Docker image. It captures the exact changes Terraform intends to make at a specific point in time. If you run terraform apply without a saved plan file you are rebuilding the image right before deploying it - picking up anything that changed in the gap. Unreviewed. Untested. Straight to production.

One flag. Most teams skip it every time.

---

## The Integrated Pipeline

Here is what the final GitHub Actions workflow looks like - two jobs, running in sequence:

```yaml
jobs:
  validate:
    name: Validate
    runs-on: ubuntu-latest
    steps:
      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Unit Tests
        run: terraform test

  plan:
    name: Plan
    needs: validate
    steps:
      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        run: terraform plan -out=ci.tfplan

      - name: Upload Plan Artifact
        uses: actions/upload-artifact@v4
        with:
          name: terraform-plan
          path: ci.tfplan
```

Validate runs first. If any check fails, plan never runs. If validate passes, plan generates the artifact and uploads it. That uploaded plan file is the immutable artifact. It gets reviewed. It gets applied. It never gets regenerated.


<img width="376" height="35" alt="image" src="https://github.com/user-attachments/assets/de1d4629-ec4d-4dc7-b003-88cb8b918e7c" />


<img width="365" height="145" alt="image" src="https://github.com/user-attachments/assets/d0d45b86-685a-4832-ae4e-d31c24166a84" />



---

## Three Sentinel Policies, Three Different Problems They Solve

**Policy 1: Instance type enforcement**

```python
allowed_instance_types = ["t2.micro", "t2.small", "t2.medium", "t3.micro", "t3.small"]

main = rule {
  all tfplan.resource_changes as _, rc {
    rc.type is not "aws_instance" or
    rc.change.after.instance_type in allowed_instance_types
  }
}
```

Someone tries to deploy a c5.4xlarge in production at 3am? Blocked. Not warned. Blocked. Before it reaches AWS.

**Policy 2: ManagedBy tag enforcement**

```python
main = rule {
  all tfplan.resource_changes as _, rc {
    rc.change.after is not null and
    rc.change.after.tags is not null and
    rc.change.after.tags["ManagedBy"] is "terraform"
  }
}
```

If a resource does not have ManagedBy = "terraform" it cannot be deployed. This sounds like bureaucracy. It is actually how you answer the question "where did this mystery EC2 instance come from and who owns it" without spending three hours in CloudTrail.

**Policy 3: Cost gate**

```python
import "tfrun"

maximum_monthly_increase = 50.0

main = rule {
  tfrun.cost_estimate.delta_monthly_cost < maximum_monthly_increase
}
```

No apply goes through if it increases monthly costs by more than $50 without explicit approval. Your budget is now enforced in code, not in a meeting.

<img width="373" height="122" alt="image" src="https://github.com/user-attachments/assets/28597bb0-4d73-47dc-9e3d-ea4b833af9f1" />


---

## The Side by Side That Makes It Click

| Component | Application Code | Infrastructure Code |
|-----------|-----------------|---------------------|
| Source of truth | Git repository | Git repository |
| Local run | npm start | terraform plan |
| Artifact | Docker image | Saved .tfplan file |
| Versioning | Semantic version tag | Semantic version tag |
| Automated tests | Unit and integration | terraform test |
| Policy enforcement | Linting and SAST | Sentinel policies |
| Cost gate | Not applicable | Cost estimation policy |
| Promotion | Image across envs | Plan across envs |
| Deployment | CI/CD pipeline | terraform apply plan |
| Rollback | Redeploy previous image | Apply previous plan |

The workflows are not just similar. They are the same workflow applied to different artifacts. Once you see it you cannot unsee it.

---

## 22 Days; What I Actually Built

Let me be honest about the list because it is longer than I expected when I started:

EC2 instances and security groups. VPCs with public and private subnets. Application Load Balancers. Auto Scaling Groups. S3 buckets for remote state. DynamoDB tables for state locking. EKS clusters. Multi-region infrastructure. Reusable Terraform modules. Terraform workspaces for environment isolation. GitHub Actions CI pipelines. CloudWatch CPU alarms. Terraform Cloud workspaces with remote state. A private module registry. Three Sentinel policies.

Most engineers do not touch this much infrastructure in their first year. I did it in 22 days with a laptop and an AWS free tier account.

---

## What Actually Changed In How I Think

Not a tool. A mental model.

I now treat infrastructure changes the same way I treat database migrations.

They are not configuration files. They are irreversible operations. Dropping a database table and destroying a VPC have the same energy - you need a plan, a review, and a rollback strategy before you touch anything. The workflow is not overhead. It is respect for the blast radius.

---

## What Was Harder Than Expected

Getting GitHub Actions to authenticate to both AWS and Terraform Cloud at the same time.

The environment variable is named TF_TOKEN_app_terraform_io and that naming convention is not obvious. It is not documented prominently. It cost me a full debugging session across Days 21 and 22 and the error message ("Required token could not be found") does not point you toward the fix.

Once you know it, it is one line. Getting there was not one line.

---

## What I Would Do Differently From Day 1

Set up Terraform Cloud on Day 3, not Day 20.

I spent weeks managing local state and passing variables inline on every command. The tfvars file and remote backend would have eliminated both problems immediately. I did it the hard way first and then migrated. Starting with the right foundation saves the migration.

---

## What Comes Next

Apply this to something real.

The challenge gave me every piece. The next step is running the complete system for infrastructure that actually matters — a production application, a real team, real consequences for getting it wrong.

That is when the discipline either holds or it does not. I want to find out.

---

## The One Thing I Will Carry Forward

The plan file is the artifact.

Build it once. Review it. Promote it. Never regenerate it.

Everything else in this workflow exists to protect that artifact from being contaminated between review and apply. If you understand that one idea you understand why every step of the workflow exists.

22 days in. The book is finished. The learning is not.

---

*Part of the 30-Day Terraform Challenge by AWS AI/ML UserGroup Kenya, Meru HashiCorp User Group, and EveOps.*

*#30DayTerraformChallenge #Terraform #DevOps #IaC #AWSUserGroupKenya #EveOps*
