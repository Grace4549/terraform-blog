# Building a Scalable Web Application on AWS with Terraform - Day 26

*Day 26 of the 30-Day Terraform Challenge*

---

Picture this.

It is Black Friday. Your e-commerce site is getting 10x normal traffic. Your servers are melting. Your on-call engineer is scrambling to spin up more instances manually. By the time they are ready, the traffic spike is over and you are now paying for idle servers until someone remembers to turn them off.

This is not a hypothetical. This is what happens when infrastructure does not scale automatically.

Today I built the system that makes that scenario impossible.

---

## Three Modules. One Cohesive System.

The architecture is three AWS primitives working in coordination:

**EC2 Launch Template** - the blueprint. Every server that spins up uses this template. Same configuration, every time, automatically. No manual setup, no configuration drift.

**Application Load Balancer** - the traffic director. Sits in front of all your servers and distributes requests across them. If a server goes down, the ALB stops sending traffic to it within 30 seconds. Users never notice.

**Auto Scaling Group** - the brain. Watches your servers constantly. Too much CPU? Add a server. Traffic drops? Remove a server. Always running exactly as many servers as you need and never more.

I built each one as a separate, reusable Terraform module. Here is why that matters.

---

## Why Three Modules Instead of One File

I could have written everything in one `main.tf` file. 400 lines of tightly coupled configuration that nobody could reuse, nobody could understand at a glance, and nobody could change safely.

Instead I split concerns cleanly:

```
modules/
├── ec2/     — launch template and security group
├── alb/     — load balancer, target group, listener
└── asg/     — auto scaling group and scaling policies
```

The magic is in how they connect. The EC2 module produces a launch template ID. The ASG module consumes it. The ALB module produces a target group ARN. The ASG module consumes that too. Terraform figures out the order automatically.

```hcl
module "asg" {
  launch_template_id  = module.ec2.launch_template_id
  target_group_arns   = [module.alb.target_group_arn]
}
```

Two lines. The entire connection between three complex AWS services. That is what good module design looks like.

<img width="647" height="111" alt="image" src="https://github.com/user-attachments/assets/e6c0f843-3ec4-4a82-85e1-ab236324a15b" />


---

## The Auto Scaling Loop - How It Actually Works

This is the part that makes the system genuinely intelligent.

CloudWatch watches the average CPU across every instance in the ASG. I defined two thresholds:

**Scale out at 70% CPU:**
When average CPU hits 70% for two consecutive 2-minute periods, a CloudWatch alarm fires. That alarm triggers an Auto Scaling policy that adds one instance. The new instance registers with the ALB target group. Traffic starts flowing to it. CPU drops.

**Scale in at 30% CPU:**
When average CPU drops to 30%, another alarm fires. The ASG removes one instance gracefully — deregisters it from the ALB first so no requests are dropped, then terminates it.

The 300 second cooldown between scaling events prevents thrashing — the system does not add and remove instances repeatedly in rapid succession.

This entire feedback loop runs without human intervention. At 3am. On Christmas Day. Every day.


<img width="550" height="106" alt="image" src="https://github.com/user-attachments/assets/af7afd8b-90c0-4b53-8277-3f0ded3918be" />




<img width="697" height="148" alt="image" src="https://github.com/user-attachments/assets/0f807fb7-f5a2-497b-81ba-ce4fd93d0020" />



---

## The Detail That Most Engineers Miss

I set `health_check_type = "ELB"` on the Auto Scaling Group and this detail matters more than it sounds.

By default, ASGs use EC2 health checks to verify that the instance is running. That is it. An instance can be running and serving 500 errors on every request and the ASG considers it healthy.

ELB health checks go further. The ALB checks whether the instance is actually returning HTTP 200 responses. If it is not, the ALB stops sending traffic to it AND the ASG marks it unhealthy and replaces it automatically.

The difference: EC2 health checks keep broken instances in rotation. ELB health checks remove them.

<img width="629" height="153" alt="image" src="https://github.com/user-attachments/assets/3a32d71c-9d1a-474f-9cb3-cf182a784ef0" />


<img width="745" height="198" alt="image" src="https://github.com/user-attachments/assets/2794a0fd-3be7-415f-bb2b-7afd403fb2fe" />


---

## What This Looks Like for a Real Company

Think about what this system gives you:

**Cost control** - you never pay for idle servers during off-peak hours. The ASG scales down automatically.

**Reliability** - unhealthy instances are replaced automatically. No on-call engineer needed for a server going down.

**Consistency** - every server that launches uses the exact same launch template. No snowflake servers with mystery configurations.

**Auditability** - every resource is tagged, every change is tracked in Terraform state, every scaling event is logged in CloudWatch.

And all of it is defined in code. Reproducible. Reviewable. Version controlled.

If the entire dev environment needs to be rebuilt from scratch, it takes one command and about 4 minutes:

```bash
terraform apply
```

---

## The Deploy

I applied the configuration, retrieved the ALB DNS, and opened it in the browser:

```
web-challenge-day26-alb-xxxxxxxxx.us-east-1.elb.amazonaws.com
```

Deployed with Terraform. Environment: dev. Served through the load balancer. Instances healthy. Alarms configured.

Then I destroyed it all cleanly:

```bash
terraform destroy
```

<img width="536" height="39" alt="image" src="https://github.com/user-attachments/assets/b604b3ce-4d8e-40c2-918b-8d990b74bcf3" />

Because paying for idle infrastructure is the old way of doing things.

---

## 26 Days In

When I started this challenge I knew what an EC2 instance was. Now I am building systems where servers appear and disappear automatically in response to real traffic, wired together through reusable modules, managed entirely through version-controlled code.

The gap between those two things is significant.

---

*Part of the 30-Day Terraform Challenge by AWS AI/ML UserGroup Kenya, Meru HashiCorp User Group, and EveOps.*

*#30DayTerraformChallenge #Terraform #AWS #AutoScaling #DevOps #IaC #AWSUserGroupKenya #EveOps*
