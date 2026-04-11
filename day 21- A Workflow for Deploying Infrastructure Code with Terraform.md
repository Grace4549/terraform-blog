# A Workflow for Deploying Infrastructure Code with Terraform

*Day 21 of the 30-Day Terraform Challenge*

---

Let me paint you a picture.

It's 11pm. James the DevOps engineer runs `terraform plan`. Looks good. He goes to make tea. His colleague quietly applies a security group change while he's gone. James comes back, runs `terraform apply`. Terraform picks up his change AND his colleague's unreviewed change. Together. In production. Port 22 is now open to the entire internet.

Nobody notices for three days.

This is not a horror story I made up. This is Tuesday for teams that skip the infrastructure deployment workflow. Today I built the safeguards that stop Tuesday from happening.

---

## What I Actually Built

A CloudWatch CPU alarm for my webserver cluster. Simple, right? One resource. But the *workflow* around it is the whole point.

```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggered when CPU exceeds 80% for 4 minutes"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}
```

One alarm. Fourteen steps to deploy it safely. Worth every one.

---

## The Seven Steps (Infrastructure Edition)

**Step 1: Branch Protection**

I know it's working because when I accidentally tried to push directly to main, GitHub slapped my hand:

> *"Changes must be made through a pull request."*

That error message is not an obstacle. It's the system working exactly as designed. Beautiful.

**Step 2: The Plan File Is Sacred**

Here's the thing nobody tells you about `terraform apply`:

```bash
# This is risky
terraform apply

# This is professional
terraform plan -out day21.tfplan
terraform apply day21.tfplan
```

The gap between plan and apply is where unreviewed changes sneak in. Someone applies something in that gap, your fresh apply picks it up, and suddenly you're applying code nobody reviewed. The saved plan file locks in exactly what was reviewed. One extra step. Non-negotiable.

<img width="530" height="32" alt="image" src="https://github.com/user-attachments/assets/4b8f4271-60d1-432e-a4a7-accde789c2fe" />


**Step 3: Feature Branch**

```bash
git checkout -b add-cloudwatch-alarms-day21
```

Make the change. Run plan again. Confirm: 1 resource to create, 0 to modify, 0 to destroy. Only then commit.

**Step 4: The PR Template That Actually Matters**

Yesterday's PRs had plan output. Today's PRs have plan output PLUS two sections that don't exist in app deployment:

*Blast radius:* What else breaks if this apply fails halfway through?

*Rollback plan:* How do we undo this at 2am when everything is on fire?

For my alarm the blast radius was low; it's monitoring, it touches nothing else. But for a VPC change? The blast radius is every single service running in that VPC. Your reviewer needs to know that BEFORE the apply, not during the incident call.

<img width="326" height="61" alt="image" src="https://github.com/user-attachments/assets/5d68369f-f4bc-4220-856e-888573795200" />


**Step 5: Two Layers of Enforcement**

Layer 1 is GitHub Actions - validate, format check, unit tests. Caught me out today: the workflow couldn't connect to Terraform Cloud because it had no token. Fixed by adding `TF_API_TOKEN` as a GitHub secret and wiring it into the workflow. Green tick achieved. 

<img width="365" height="27" alt="image" src="https://github.com/user-attachments/assets/c60f3b15-4b16-4a97-a00f-aa8c55cefb66" />


Layer 2 is Sentinel - policy-as-code that runs after plan, before apply. My policy:

```python
import "tfplan/v2" as tfplan

allowed_instance_types = ["t2.micro", "t2.small", "t2.medium", "t3.micro", "t3.small"]

main = rule {
  all tfplan.resource_changes as _, rc {
    rc.type is not "aws_instance" or
    rc.change.after.instance_type in allowed_instance_types
  }
}
```

Plain English: try to deploy a beefy expensive instance type and Sentinel blocks you. Hard stop. Not a warning. Not a suggestion. Blocked.

`terraform validate` asks: *is this valid Terraform?*
Sentinel asks: *is this allowed?*

Different questions. Both matter.

**Step 6 - Merge and Tag**

```bash
git tag -a "v1.4.0" -m "Add CPU alarm for webserver cluster"
git push origin v1.4.0
```

Tags are version pins. Module consumers pin to `1.4.0` deliberately. They don't accidentally get your next change just because they pulled from main.

<img width="355" height="254" alt="image" src="https://github.com/user-attachments/assets/a214b533-a1ee-4b9a-a49d-4188151cf505" />


**Step 7 - Apply from the Saved Plan**

```bash
terraform apply day21.tfplan
```

<img width="376" height="80" alt="image" src="https://github.com/user-attachments/assets/886c3782-e8e0-434e-91be-19862655fd4c" />


Output from Terraform Cloud:
```
aws_cloudwatch_metric_alarm.high_cpu: Creating...
aws_cloudwatch_metric_alarm.high_cpu: Creation complete after 0s
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
cloudwatch_alarm_name = "webserver-cluster-high-cpu"
```
<img width="370" height="97" alt="image" src="https://github.com/user-attachments/assets/7cd53e92-1ff7-4feb-8dab-b3e9a258e817" />


Then immediately:

```bash
terraform plan
# No changes. Your infrastructure matches the configuration.
```

That clean follow-up plan is the receipt. Apply did exactly what it was supposed to. Nothing more.

---

## The Four Safeguards App Deployment Doesn't Have

**Plan file pinning** - save the plan, apply the plan, close the drift window.

**Approval gates** - Terraform Cloud set to manual apply. Every run waits for a human to click Confirm before touching AWS.

<img width="371" height="154" alt="image" src="https://github.com/user-attachments/assets/a64c788e-d001-4d28-afb9-6060908aeb88" />


**State versioning** - Terraform Cloud keeps every state version. You will need to restore a previous state exactly once, at the worst possible moment. Know where it is before that moment arrives.

<img width="371" height="158" alt="image" src="https://github.com/user-attachments/assets/83e46082-4d3a-44f7-ab81-2b41a9226f1c" />


**Blast radius documentation** - write it in the PR. Not in the incident report.

---

## What Breaks When You Skip Steps

Skip branch protection → anyone applies anything from anywhere.

Skip plan file pinning → unreviewed drift enters your deployment silently.

Skip blast radius docs → you find out what depends on what by watching it break.

Skip approval gates → a bad plan auto-applies while you're asleep.

Skip tagging → module consumers get your breaking changes automatically.

The workflow isn't overhead. Each step exists because a team skipped it once and lost something they couldn't get back — a database, a weekend, a production environment.

---

## Today's Unexpected Win

Branch protection blocked my direct push to main and I was briefly annoyed. Then I remembered: that's exactly what it's supposed to do. The system protecting me from myself is the whole point.

21 days in. The discipline is the feature.

---

*Part of the 30-Day Terraform Challenge by AWS AI/ML UserGroup Kenya, Meru HashiCorp User Group, and EveOps.*

*#30DayTerraformChallenge #Terraform #DevOps #IaC #AWSUserGroupKenya #EveOps*
