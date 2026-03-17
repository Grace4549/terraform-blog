# Terraform Day 3: Deploying My First Server with Terraform: A Beginner's Guide

Today was a big step in my Cloud & DevOps journey! I used Terraform to provision and deploy a fully functional web server on AWS.

Instead of manually clicking through the AWS console, I defined everything as code. This made the process repeatable, faster, and much easier to manage.

---

## What I Built

Using Terraform, I deployed:

* An AWS EC2 instance (Amazon Linux 2)
* A custom Security Group allowing HTTP (80) and SSH (22)
* A web server configured automatically using a user data script

Once deployed, I was able to access my server via a public IP and see my custom webpage live in the browser.

---

## Key Concepts I Practiced

This project helped me deeply understand:

**1. Provider Configuration**
I connected Terraform to AWS using my IAM user (`terraform-user`) and configured the `us-east-1` region.

**2. Resource Creation**
I defined infrastructure using Terraform resources:

* `aws_instance`
* `aws_security_group`

**3. Infrastructure as Code (IaC)**
Instead of manual setup, everything was declared in `main.tf`, making it reusable and version-controlled.

**4. Automation with User Data**
I used a bash script to:

* Install Apache
* Start the web server
* Deploy a custom HTML page

---

## My Live Server

After deployment, I accessed my application using:

```
http://100.48.68.110/
```

Seeing my custom page live felt incredibly rewarding and this is where everything came together.

---

## Challenges I Faced (and What I Learned)

This wasn’t a smooth ride and that’s where the real learning happened.

**1. EC2 Instance Failed to Launch**
I initially used `t2.micro`, which is no longer free-tier eligible in my setup.
 Fix: I switched to `t3.micro` after carefully reading the Terraform error output.

---

**2. AWS Authentication Issues**
Terraform kept failing during authentication.
 Root cause: I had deactivated my access key previously.
 Fix: Reactivated the key and verified using AWS CLI.

---

**3. HTML Changes Not Reflecting**
Even after updating my code, the webpage didn’t change.
 Lesson: Terraform does not re-run `user_data` on existing instances.
 Fix: Destroyed and recreated the instance:

```
terraform destroy
terraform apply
```

This was a major “aha” moment for me.

---

## Architecture Overview

My setup followed a simple but real-world cloud architecture:

* Internet → Security Group → EC2 Instance
* Security Group allowed:

  * HTTP (80)
  * SSH (22)
* EC2 instance served a web page using Apache

<img width="306" height="311" alt="image" src="https://github.com/user-attachments/assets/de2ec523-d0db-42a0-9e50-843b722ef07b" />


---

## Clean-Up (Important DevOps Practice)

After confirming everything worked, I ran:

```
terraform destroy
```

This removed all resources (EC2 instance, security group, etc.).

This step is critical in real-world cloud environments to:

* Avoid unnecessary costs
* Keep infrastructure clean
* Practice responsible resource management

---

## What This Project Taught Me

This wasn’t just about deploying a server, it changed how I think about infrastructure.

I learned:

* How to debug real Terraform errors
* The importance of reading error messages carefully
* That infrastructure should be **automated, not manual**

Most importantly, I gained confidence in working with AWS and Terraform in a real setup.

---

## What’s Next?

I’m continuing to build more hands-on projects to strengthen my Cloud & DevOps skills, including multi-tier architectures, load balancing, and CI/CD pipelines.

This is just the beginning.

---

✨ *Hello, Grace just completed Terraform Day 3 challenge — and I’m excited to keep growing in Cloud & DevOps!*
