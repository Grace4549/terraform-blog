# Building Reusable Infrastructure with Terraform Modules

Day 8 of the 30-Day Terraform Challenge, and today everything clicked.

For the past week, I have been writing Terraform code that works. Today I learned 
how to write Terraform code that scales. There is a big difference.

---

## The Problem I Did Not Know I Had

Look at any infrastructure codebase that has been around for a while, and you will 
see the same thing. The same security group copied three times, the same load 
balancer configuration in dev, staging, and production, the same EC2 setup 
repeated everywhere with slightly different names.

It works. Until it doesn't.

The moment you need to change something like a port number, a health check interval, or 
an instance type, you are hunting through multiple files, making the same edit in 
multiple places, and hoping you did not miss one. That is not infrastructure as code. 
That is infrastructure as organised chaos.

Modules fix this. A module is a reusable package of Terraform code. You write the 
logic once and call it as many times as you need with different inputs. Think of it 
like a blueprint. Dev is a small house built from the blueprint. Production is a 
bigger house built from the same blueprint. Same design, different sizes, one source 
of truth.

---

## Building the Module

The first thing I did was create the directory structure:

<img width="253" height="170" alt="image" src="https://github.com/user-attachments/assets/68c049c0-25d0-41e6-b047-ecc093488120" />


The `modules` folder holds the blueprint. The `live` folder holds the actual 
environments that use it. This separation is intentional. The module never knows 
or cares which environment is calling it.

Inside the module, every configurable value becomes an input variable:
```hcl
variable "cluster_name" {
  description = "The name to use for all cluster resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the cluster"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type        = number
}
```

Notice that `cluster_name`, `min_size`, and `max_size` have no defaults. They are 
required. If you call this module without passing them in, Terraform will stop 
immediately and tell you exactly what is missing. That is a feature, not a bug. 
It forces whoever is calling the module to be deliberate about what they are 
deploying.

The module also defines outputs. The values it exposes to whoever calls it:
```hcl
output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value       = aws_autoscaling_group.asg.name
  description = "The name of the Auto Scaling Group"
}
```

Without outputs, the values produced inside the module stay hidden. The caller 
would have no way to know the load balancer URL after deployment. Outputs are how 
a module communicates back to the world.

---

## Calling the Module from Dev and Production

This is where it gets satisfying. Two completely separate environments, same module, 
different inputs:
```hcl
# dev
module "webserver_cluster" {
  source        = "../../../../modules/services/webserver-cluster"
  cluster_name  = "webservers-dev"
  instance_type = "t3.micro"
  min_size      = 1
  max_size      = 2
}
```
```hcl
# production
module "webserver_cluster" {
  source        = "../../../../modules/services/webserver-cluster"
  cluster_name  = "webservers-production"
  instance_type = "t3.micro"
  min_size      = 1
  max_size      = 2
}
```

The module code did not change. Not a single line. Only the inputs changed.

---

## Deploying and Confirming

I ran `terraform init` and `terraform apply` from the dev directory and watched 
14 resources spin up from a single module call.

<img width="343" height="64" alt="image" src="https://github.com/user-attachments/assets/08a994e6-9218-404a-8dda-93c468ebb624" />


<img width="344" height="70" alt="image" src="https://github.com/user-attachments/assets/c54af4f5-b0d7-4a7e-8485-cd653ed5e1d9" />


The output confirmed the ALB DNS name:

<img width="332" height="18" alt="image" src="https://github.com/user-attachments/assets/a99ae46a-a74e-4820-825d-4c4095ee5d0d" />


I destroyed dev, switched to production and applied again. Same result, different 
names, different scale.

<img width="708" height="138" alt="image" src="https://github.com/user-attachments/assets/18c94eda-f509-4559-90d4-a73601b5e7fb" />


---

## The Refactoring Moment

Here is what made Day 8 special. The module I built is not new infrastructure. 
It is a refactor of everything I built in Days 3 to 5.

Back then, I had VPCs, subnets, security groups, EC2 instances, Auto Scaling Groups, 
and load balancers all hardcoded across multiple files. It worked, but it was rigid. 
Moving that code into a module forced me to decide every single value:
Is this something that changes between environments, or is it an internal detail 
that should stay fixed?

Values like `cluster_name`, `min_size`, and `instance_type` became variables because 
they need to differ between dev and production. VPC CIDR blocks, health check 
intervals, and availability zones stayed hardcoded because they are implementation 
details that callers should not need to think about.

That decision-making process is the real skill. Anyone can write Terraform code. 
Writing a module that is genuinely easy for someone else to use is a different thing 
entirely.

---

## What Day 8 Taught Me

Modules aren't just nice to have. They are how real infrastructure teams work. 
When your organisation has 10 teams all deploying web servers, you do not want 10 
different versions of the same infrastructure. You want one well-tested module that 
everyone calls with their own inputs.

The moment I saw the same module deploy successfully to dev and production with 
nothing but different input values, I understood why this is considered the most 
important abstraction Terraform offers.

Write it once. Use it everywhere. Change it in one place.

Day 9, let's go.

#30DayTerraformChallenge #TerraformChallenge #Terraform #IaC #DevOps 
#HashiCorp #CloudComputing #PlatformEngineering #LearningInPublic 
#100DaysOfCloud #AWSUserGroupKenya #EveOps
