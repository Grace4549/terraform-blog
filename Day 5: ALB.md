# Managing High Traffic Applications with AWS Elastic Load Balancer and Terraform

Today I scaled my infrastructure from Day 4 by adding an AWS Application Load Balancer (ALB) in front of my EC2 cluster and explored Terraform state management in depth. This was a critical step toward making my app truly production-ready.

## Scaling Infrastructure with ALB and Auto Scaling Group
```
# EC2 Instances
resource "aws_instance" "app" {
  count         = var.instance_count
  ami           = var.ami
  instance_type = "t3.micro"
  subnet_id     = element(aws_subnet.public.*.id, count.index % length(aws_subnet.public.*.id))
  security_groups = [aws_security_group.instance_sg.id]

  tags = {
    Name = "terraform-instance-${count.index + 1}"
  }
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public.*.id
}

# Target Group
resource "aws_lb_target_group" "tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }
}

# Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name                      = "app-asg"
  max_size                  = 5
  min_size                  = 2
  desired_capacity          = var.instance_count
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.tg.arn]
  vpc_zone_identifier = aws_subnet.public.*.id
}
```

I started by extending my Terraform configuration to include:

*ALB – Distributes HTTP traffic across all EC2 instances, making my app highly available.

*Target Group – Performs health checks on instances to ensure only healthy instances receive traffic.

*Listener – Listens on port 80 and forwards requests to the target group.

*Auto Scaling Group (ASG) – Ensures the desired number of instances are running, automatically replacing failed instances.

-Each EC2 instance was given a unique Name tag using:

```Name = "terraform-instance-${count.index + 1}"```

This ensures proper identification and allows Terraform to track state correctly.

## Understanding Terraform State

I ran two experiments today to explore how Terraform handles state:

### Manual State File Edit:
I tried changing the Name tag in terraform.tfstate. Terraform did not detect any changes, showing that it only compares the live infrastructure against code, not arbitrary state edits.
<img width="927" height="59" alt="image" src="https://github.com/user-attachments/assets/e2608fc5-4b21-4d39-890f-f333ce3c1981" />


### State Drift in AWS Console:
I manually changed a Name tag on one instance. Initially, since the tag wasn’t in my Terraform code, no drift was detected. After adding the tag in code, Terraform correctly planned to revert the manual change, proving the importance of defining all managed attributes in code.

<img width="502" height="278" alt="image" src="https://github.com/user-attachments/assets/7b35dd08-1465-4aea-9e1c-f9625ca8b909" />

## Key takeaway: Terraform state is the single source of truth, and only attributes defined in code are tracked for drift.

## Challenges and Fixes

The main challenge was that my EC2 instances initially didn’t have Name tags in code. As a result, Terraform did not detect manual tag changes, which confused my state experiments. I fixed this by defining the Name tag in the EC2 resource.

## Learnings

Through this exercise, I learned:

-Terraform only manages what is defined in code; any live changes outside Terraform require code updates to be tracked.

-Defining tags and identifiers is critical for state drift detection.

-Remote state storage and state locking are essential in team environments to avoid conflicts and corruption.

-The ALB + ASG combination provides scalable, fault-tolerant architecture that can handle high traffic seamlessly.

## Block Types Used
| Block Type | Purpose | When to Use | Example |
|------------|---------|------------|--------|
| provider   | Configures the cloud provider | Once per provider at the start of your configuration | `provider "aws" { region = "us-east-1" }` |
| resource   | Defines infrastructure to create | Every piece of infrastructure you want Terraform to manage | `resource "aws_instance" "app" { ami = var.ami instance_type = "t3.micro" }` |
| variable   | Declares input variables | To avoid hardcoding values and make configuration reusable | `variable "instance_count" { default = 2 }` |
| output     | Exposes values after apply | To retrieve important info like DNS names, IPs, or IDs | `output "alb_dns_name" { value = aws_lb.alb.dns_name }` |
| data       | Reads existing resources not managed by your config | To reference resources created outside Terraform or by another module | `data "aws_availability_zones" "all" {}` |

## Conclusion:

Scaling infrastructure with ALB and ASG while understanding Terraform state gave me confidence in managing production-ready applications. I now appreciate how state drives Terraform’s ability to reconcile infrastructure, detect drift, and maintain reliability across environments.

ALB Live Test: I confirmed by visiting the ALB DNS name that traffic is evenly distributed across instances, and stopping one instance did not disrupt access to the application.

<img width="463" height="100" alt="image" src="https://github.com/user-attachments/assets/b8084869-4558-4942-beb0-073cf4ea07c7" />
