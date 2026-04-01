# The Importance of Manual Testing in Terraform

Day 17 of the 30-Day Terraform Challenge and today was humbling
in the best possible way.

I have been building infrastructure for 16 days. Writing modules,
managing state, securing secrets, refactoring for production grade
standards. Today I stopped building and started verifying. And
what I found was instructive.

---

## Why Manual Testing Still Matters

There is a temptation to skip manual testing once you have
automated tests. If the pipeline passes, everything is fine.
Right?

Not quite.

Automated tests check what you programmed them to check. Manual
tests catch the things you did not think to automate. The wrong
AMI. A security group rule that looks correct in code but behaves
differently in practice. An instance that passes Terraform
validation but fails to install Apache because the package
repository no longer exists.

Today I found all of these. With a checklist.

---

## The Checklist Approach

A manual test without a checklist is just clicking around hoping
things look right. Today I built a structured test plan covering
five categories:

**Provisioning verification** - does Terraform itself work
correctly? Does `terraform validate` pass? Does `terraform plan`
show the right resources? Does `terraform apply` complete cleanly?

**Resource correctness** - are the resources that exist in AWS
exactly what the configuration describes? Right names, right tags,
right security group rules?

**Functional verification** - does the infrastructure actually
work? Does the ALB return the expected response? Do instances
pass health checks?

**State consistency** - does `terraform plan` return No changes
immediately after a fresh apply? If it does not, something in
the configuration does not match reality.

**Regression check** — make a small deliberate change. Does the
plan show only that change and nothing unexpected?

Working through each category in order is what separates a
real test from a gut feel.

---

## What the Tests Found

Most things passed. But one failure was significant.

**FAIL: Instances unhealthy on initial deployment**
```
Command: terraform apply -auto-approve
Expected: Instances healthy in target group
Actual: Instances failing health checks repeatedly
```

The AMI I had been using - `ami-07d02ee1eeb0c996c` - turned out
to be Debian Buster. Debian Buster reached end-of-life and its
package repositories now return 404. So when the user data script
ran `apt-get install apache2` the package could not be found.
Instances kept starting, failing to install Apache, failing
health checks and being terminated. The ASG kept launching
replacements. An expensive loop.

The fix was finding the latest Amazon Linux 2 AMI using AWS CLI:
```powershell
aws ec2 describe-images --owners amazon `
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" `
  "Name=state,Values=available" `
  --query "sort_by(Images, &CreationDate)[-1].ImageId" `
  --region us-east-1
```

Result: `ami-0622c21dd3d2b1075`

After updating the AMI and switching the user data back to `yum`
and `httpd` everything worked:

<img width="820" height="281" alt="image" src="https://github.com/user-attachments/assets/25350ee4-ffe4-46c1-be55-34b673b769a7" />


That failure would not have been caught by `terraform validate`.
It would not have been caught by `terraform plan`. It was only
caught by actually running the infrastructure and verifying
the response.

That is why manual testing exists.

---

## Input Validation in Action

Two of the most satisfying test results today were the validation
tests. Passing an invalid environment:
```powershell
terraform plan -var="environment=invalid"
```
```
Error: Invalid value for variable
Environment must be dev, staging, or production.
```

<img width="548" height="191" alt="image" src="https://github.com/user-attachments/assets/80eddd64-6487-43c4-ad1b-69562fed31c1" />


Passing an invalid instance type:
```powershell
terraform plan -var="instance_type=m5.large"
```
```
Error: Invalid value for variable
Instance type must be a t2 or t3 family type.
```

Terraform stopped at plan time. Nothing was deployed. Nothing
was charged. The error message was clear and actionable.

This is what input validation buys you - mistakes caught before
they cost anything.

---

## Cleanup Is Not Optional

After every test run I destroyed all resources immediately and
verified the cleanup using AWS CLI:
```powershell
aws ec2 describe-instances `
  --filters "Name=tag:ManagedBy,Values=terraform" `
  --query "Reservations[*].Instances[*].InstanceId" `
  --region us-east-1

aws elbv2 describe-load-balancers `
  --query "LoadBalancers[*].LoadBalancerArn" `
  --region us-east-1
```

Both returned empty. Clean.

The author's point in Chapter 9 is that cleanup is harder than
it sounds. Terraform occasionally leaves orphaned resources when
a destroy fails partway through. Security groups, network
interfaces and load balancers are common culprits. Without
explicit verification after every destroy these accumulate
silently and run up costs.

Cleanup is not the last step. It is part of the test.

---

## What Day 17 Taught Me

Manual testing is not a consolation prize for engineers who
have not written automated tests yet. It is the foundation that
automated tests are built on. Every failure you find manually
is a test case you can automate. Every gap in your checklist
is a gap in your automated suite.

Today I found a real bug in real infrastructure using a
structured checklist. That is what testing is for.

Day 18, let's go.

#30DayTerraformChallenge #TerraformChallenge #Terraform #Testing
#DevOps #IaC #HashiCorp #CloudComputing #PlatformEngineering
#LearningInPublic #100DaysOfCloud #AWSUserGroupKenya #EveOps
