# Deploying a Highly Available Web App on AWS Using Terraform

Day 4 of the 30-Day Terraform Challenge

On Day 3, I deployed a single EC2 web server. It worked, yes, but it wasn’t reliable. If that one server failed, everything would go down.

So today, I took it a step further and built a highly available, load-balanced web application using Terraform on AWS.

# What I Built:
Instead of one server, I created a system with:
-Multiple EC2 instances (a cluster)
-An Auto Scaling Group (ASG) to manage them
-An Application Load Balancer (ALB) to distribute traffic
-A Target Group + Listener to connect everything

Now, if one server fails, the system will still work. That’s real-world infrastructure.

# Key Concepts I Learned
1. DRY Principle (Don’t Repeat Yourself)
I removed all hardcoded values and used input variables instead. This means: I can change region, port, instance type easily. There's no need to edit the main code every time

2. Launch Template (Modern AWS Standard)
At first, I tried using Launch Configuration, but AWS no longer supports it for new accounts.
I fixed it by switching to a Launch Template, which is the modern and recommended way.

3. Auto Scaling Group (ASG)
This automatically keeps at least 2 servers running and can scale up to 5 if needed

4. Application Load Balancer (ALB)

The ALB receives traffic from users, sends requests to healthy servers and ensures no single server gets overloaded

# Architecture 
User → Load Balancer → Target Group → Auto Scaling Group → EC2 Instances

# My Terraform Code 
Provider Configuration
 ```
 provider "aws" {
  region  = var.aws_region
  profile = "terraform-user"
}
```
This connects Terraform to AWS using my configured profile.

 Getting Default VPC and Subnets
```
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
```
Instead of hardcoding networking values, I dynamically fetch: The default VPC and all subnets inside it
This makes my setup reusable.

 Security Group
 ```
resource "aws_security_group" "web_sg" {
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```
This allows:
-HTTP traffic (users accessing my app)
-SSH (for debugging if needed)

 Launch Template
 ```
resource "aws_launch_template" "web_lt" {
  image_id      = var.ami_id
  instance_type = var.instance_type
}
```
This defines how each EC2 instance should be created:
-AMI (OS)
-Instance type
-Security group
-Startup script (user_data)

 Auto Scaling Group
```
resource "aws_autoscaling_group" "web_asg" {
  min_size = 2
  max_size = 5
}
```
This ensures there are minimum of 2 servers always running and can scale up when needed

 Load Balancer
 ```
resource "aws_lb" "web_alb" {
  load_balancer_type = "application"
}
```
This distributes incoming traffic across all instances.

 Target Group + Listener
 ```
resource "aws_lb_target_group" "web_tg" {}
resource "aws_lb_listener" "web_listener" {}
```
These connects Load Balancer to EC2 instances

 Deployment Confirmation

After running:
````
terraform apply
````
I got an ALB DNS URL, opened it in my browser, and saw my web page running.
<img width="502" height="232" alt="image" src="https://github.com/user-attachments/assets/8a31dcbb-f01d-4add-adcb-09b870fda6bf" />


 That confirmed:
Load balancer is working,
Instances are healthy, and
Traffic is being routed correctly

# Challenges I Faced (And Fixed)
I used deprecated Launch Configuration but I fixed it by switching to Launch Template,
I had used the wrong attribute (alb_target_group_arn) but then fixed by using lb_target_group_arn

These mistakes helped me understand Terraform deeper.

# Infrastructure Lifecycle

Today I fully understood: terraform init → terraform plan → terraform apply → terraform destroy

And yes, after testing everything, I destroyed all resources to avoid charges.

This project helped me move from: just deploying a server to building production-style infrastructure

I now understand how real systems stay:
-Available
-Scalable
-Fault-tolerant
