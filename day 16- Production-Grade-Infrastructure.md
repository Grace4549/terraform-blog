# Creating Production-Grade Infrastructure with Terraform

Day 16 of the 30-Day Terraform Challenge and today was a reality check.

Not a fun one. A necessary one.

I have been building Terraform infrastructure for 15 days. It works. 
It deploys. It does what I tell it to do. But today I held it up 
against a production-grade checklist and asked a harder question; 
would I trust this in production?

The answer was: not quite yet.

---

## The Checklist That Changes How You Think

Chapter 8 introduces a production-grade infrastructure checklist 
covering five areas: code structure, reliability, security, 
observability and maintainability. I went through every item and 
scored my existing infrastructure honestly.

Some things I had right. Many things I had not thought about at all.

That is the point of the exercise. The gap between infrastructure 
that works and infrastructure that is production-ready is wider 
than most engineers expect, and the checklist makes that gap 
impossible to ignore.

---

## The Three Changes That Mattered Most

### Consistent Tagging - The One Nobody Takes Seriously Until They Should

Before today every resource had its own tags written individually. 
Same keys, different values, scattered everywhere. The moment you 
need to add a new tag to every resource you are hunting through 
every file making the same change dozens of times.

The fix is a `common_tags` locals block:
```hcl
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = var.team_name
  }
}
```

Then merge it onto every resource:
```hcl
resource "aws_vpc" "main" {
  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-vpc"
  })
}
```

One change. Every resource updated. That is the kind of elegance 
that makes infrastructure maintainable at scale.

### create_before_destroy - The Lifecycle Rule That Prevents Downtime

Without this lifecycle rule, updating a launch template destroys 
the old one before creating the new one. There is a gap. During 
that gap, no new instances can launch. In production that gap is 
downtime.
```hcl
lifecycle {
  create_before_destroy = true
}
```

Three lines. Zero downtime gap. I also learned that `name_prefix` 
is required alongside this; AWS does not allow two Auto Scaling 
Groups with the same name to exist at the same time, and 
`create_before_destroy` needs them to coexist briefly during 
the transition.

### Input Validation - Catching Mistakes Before They Cost You

Before today my variables accepted anything. Pass 
`environment=oops` and Terraform would happily try to deploy 
it. With validation blocks, invalid values are caught at plan 
time before a single resource is touched:
```hcl
variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "instance_type" {
  type    = string
  default = "t3.micro"

  validation {
    condition     = can(regex("^t[23]\\.", var.instance_type))
    error_message = "Instance type must be a t2 or t3 family type."
  }
}
```

<img width="571" height="222" alt="image" src="https://github.com/user-attachments/assets/b2ae4078-53ed-4614-9a29-cb1cc18f33a0" />



Terraform stopped immediately with a clear message. No partial 
deployments. No confusion. Just a clear signal that something 
was wrong before anything was touched.

---

## Observability - Knowing When Things Go Wrong

Production infrastructure without alarms is infrastructure you 
are flying blind on. Today I added a CloudWatch alarm that 
monitors CPU utilization across the Auto Scaling Group:
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

The threshold is 80%. Two evaluation periods of 2 minutes each 
means the alarm only fires after 4 minutes of sustained high CPU 
- not every brief spike. When it fires, a notification goes to 
an SNS topic that can alert your team however they prefer.


<img width="728" height="320" alt="image" src="https://github.com/user-attachments/assets/8df1c7bd-c813-478f-ad40-6ed59f54da76" />


---

## Automated Testing with Terratest

The last piece was understanding automated infrastructure testing. 
Terratest is a Go-based framework that deploys your Terraform 
infrastructure, runs assertions against it and destroys it 
automatically:
```go
func TestWebserverCluster(t *testing.T) {
  t.Parallel()

  terraformOptions := terraform.WithDefaultRetryableErrors(t, 
    &terraform.Options{
      TerraformDir: "../",
      Vars: map[string]interface{}{
        "cluster_name":  "test-cluster",
        "instance_type": "t3.micro",
        "min_size":      1,
        "max_size":      2,
        "environment":   "dev",
      },
    })

  defer terraform.Destroy(t, terraformOptions)
  terraform.InitAndApply(t, terraformOptions)

  albDnsName := terraform.Output(t, terraformOptions, "alb_dns_name")
  http_helper.HttpGetWithRetry(
    t, "http://"+albDnsName, nil, 200, "Hello", 30, 10*time.Second,
  )
}
```

The `defer terraform.Destroy` line is the most important line in 
the whole test. It guarantees cleanup even if the test fails 
halfway through. Without it a failing test leaves real AWS 
resources running and incurring costs indefinitely.

Manual testing tells you if something works right now. Automated 
testing tells you if it still works after every change.

---

## The Honest Gaps

Not everything got fixed today. `prevent_destroy` on critical 
resources and a full IAM least-privilege audit are still on 
the backlog. In a real team those become tickets. Production-grade 
is a standard to work towards continuously - not a checkbox you 
tick once.

The checklist does not exist to make you feel bad about your 
existing code. It exists to show you exactly where to go next.

---

## What Day 16 Taught Me

There is a version of Terraform code that works. And there is a 
version that a team can trust, maintain, debug at 2am, and hand 
off to someone else without a lengthy explanation.

Today I learned what separates those two versions, and started 
closing the gap.

Day 17, let's go.
