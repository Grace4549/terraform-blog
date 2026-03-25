# How Conditionals Make Terraform Infrastructure Dynamic and Efficient

Day 11 of the 30-Day Terraform Challenge and today I stopped writing 
separate configurations for different environments. One configuration. 
One variable. Completely different infrastructure. Let me show you how.

---

## The Problem I Was Solving

Until today if I wanted dev to have small instances and production to 
have large ones I had two choices; duplicate the entire configuration 
or hardcode everything and change it manually every time. Both options 
are terrible.

Conditionals fix this. They let a single configuration make smart 
decisions based on context. Dev gets what dev needs. Production gets 
what production needs. Zero duplication.

---

## The Ternary Operator; Terraform's Decision Maker

The core conditional in Terraform is the ternary expression:
```hcl
condition ? value_if_true : value_if_false
```

Simple. Powerful. And when combined with `locals` it becomes the 
cleanest pattern in all of Terraform.

---

## locals; Where All Decisions Live

The wrong way to use conditionals is scattering ternary operators 
directly inside resource arguments. The right way is centralising 
all decisions in a `locals` block and referencing them from resources.
```hcl
locals {
  is_production     = var.environment == "production"
  instance_type     = local.is_production ? "t3.medium" : "t3.micro"
  min_size          = local.is_production ? 3 : 1
  max_size          = local.is_production ? 10 : 3
  enable_monitoring = local.is_production
}
```

`is_production` is calculated once. Everything else references it. 
If the definition of production ever changes, say you add a 
`staging-production` environment, you change one line and every 
decision updates automatically.

When I applied with `environment=dev`:

<img width="332" height="82" alt="image" src="https://github.com/user-attachments/assets/21937925-83aa-4adb-b84c-69d73885e6c4" />


When I applied with `environment=production`:

<img width="639" height="151" alt="image" src="https://github.com/user-attachments/assets/eba2482a-a200-4dc0-a88b-01cc0a6951c3" />


Same configuration. One variable changed. Completely different 
infrastructure.

---

## Making Resources Optional with count

Sometimes you want a resource to exist in production but not in dev. 
CloudWatch alarms cost money. Detailed monitoring is overkill for dev. 
The `count = condition ? 1 : 0` pattern makes entire resources optional.
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count             = var.enable_detailed_monitoring ? 1 : 0
  alarm_name        = "${var.cluster_name}-high-cpu"
  metric_name       = "CPUUtilization"
  threshold         = 80
  alarm_description = "CPU utilization exceeded 80%"
}
```

`count = 1` — resource is created. `count = 0` — resource is skipped. 
No errors. No warnings. Terraform just moves on.

When monitoring was enabled:

<img width="346" height="67" alt="image" src="https://github.com/user-attachments/assets/4ee2d03b-ee01-4390-a674-3e5dbe85cd5a" />


## The Trap Nobody Warns You About

Here is something that will catch you off guard. When a resource uses 
`count = condition ? 1 : 0` you cannot reference it like a normal 
resource in your outputs. If count is 0 the resource does not exist 
and Terraform throws an index out of range error.

This crashes when monitoring is disabled:
```hcl
output "alarm_arn" {
  value = aws_cloudwatch_metric_alarm.high_cpu.arn
}
```

This works correctly every time:
```hcl
output "alarm_arn" {
  value = var.enable_detailed_monitoring ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : null
}
```

The ternary guard returns `null` when the resource does not exist 
instead of crashing. Apply this pattern to every output that 
references a conditionally created resource without exception.

---

## Input Validation; Catching Mistakes Before They Deploy

Today I also learned about validation blocks. They catch invalid 
variable values at plan time before a single resource is touched.
```hcl
variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}
```

I tested it by passing `environment=invalid` and Terraform stopped 
immediately with a clear error message:

<img width="346" height="141" alt="image" src="https://github.com/user-attachments/assets/cc0606d8-fcbe-418b-aa15-05c18fff5975" />


No resources were created. No partial deployments. Just a clear 
message telling you exactly what went wrong. This is one of the most 
practical features for modules used across teams — it makes 
misconfiguration impossible to miss.

---

## Brownfield vs Greenfield; One Module, Two Modes

The last pattern today was using conditionals with data sources. 
The goal was making a module work in two completely different modes 
with a single boolean toggle.

Greenfield — creates a brand new VPC:
```hcl
resource "aws_vpc" "new" {
  count      = var.use_existing_vpc ? 0 : 1
  cidr_block = "10.0.0.0/16"
}
```

Brownfield — looks up an existing VPC:
```hcl
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  tags  = { Name = "existing-vpc" }
}
```

Either way the rest of the configuration uses the same local:
```hcl
locals {
  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.new[0].id
}
```

One toggle. Two completely different deployment modes. The rest of 
the configuration never needs to know which one it is running in.

---

## What Day 11 Taught Me

Conditionals are not just a convenience feature. They are how you 
build infrastructure that is genuinely environment-aware without 
maintaining multiple codebases.

The `locals` pattern, the `count = condition ? 1 : 0` pattern, 
the ternary guard on outputs, and input validation together form 
a complete toolkit for writing Terraform configurations that are 
smart, safe and scalable.

One configuration. Any environment. No duplication.

Day 12, let's go.
