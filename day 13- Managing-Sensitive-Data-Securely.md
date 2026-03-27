# How to Handle Sensitive Data Securely in Terraform

Day 13 of the 30-Day Terraform Challenge and today was the day 
Terraform got serious.

Every infrastructure deployment has secrets. Database passwords. 
API keys. Tokens. And if you are not careful, Terraform will 
helpfully scatter those secrets across your codebase, your Git 
history, and your state files without you even noticing.

Today I learned exactly where secrets leak in Terraform and how 
to close every single leak path. This is the stuff that gets 
engineers fired when it goes wrong in production.

---

## The Three Ways Secrets Leak in Terraform

### Leak Path 1: Hardcoded in .tf Files

This is the most obvious mistake and somehow still the most common.
```hcl
resource "aws_db_instance" "example" {
  username = "admin"
  password = "SuperSecretPassword!"
}
```

The moment you write this and run `git add`, that password is in 
your Git history. Forever. Even if you delete it in the next 
commit it still exists in the history. The only fix at that point 
is a full Git history rewrite — which is painful, disruptive and 
often incomplete.

The secure version fetches the secret at runtime from AWS Secrets 
Manager and never touches your `.tf` files:
```hcl
resource "aws_db_instance" "example" {
  username = local.db_credentials["username"]
  password = local.db_credentials["password"]
}
```

### Leak Path 2: Variable Default Values

This one is sneakier. Engineers know not to hardcode secrets 
directly so they use variables instead. But then they add a 
default value for convenience:
```hcl
variable "db_password" {
  default = "SuperSecretPassword!"
}
```

That default value is stored in your `.tf` file. Which gets 
committed to Git. Same problem, different location.

The fix is simple! Never give secret variables a default value 
and always mark them sensitive:
```hcl
variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}
```

No default. Terraform will prompt for it or read it from an 
environment variable. The secret never touches your source code.

### Leak Path 3: The State File

This is the one that surprises everyone. Even when you close 
the first two paths perfectly; no hardcoding, no defaults, 
secrets fetched from Secrets Manager. Terraform still stores 
every resource attribute in `terraform.tfstate` in plaintext.

I proved this today by searching the state file after a clean 
deployment:

<img width="384" height="123" alt="image" src="https://github.com/user-attachments/assets/68a966c1-8a7d-4411-9a47-84eac54ab2c3" />


There it was. The password. In plaintext. In the state file. 

This is not a bug. It is how Terraform works. It needs to 
store the current state of every resource to calculate what 
needs to change on the next plan. The fix is not to prevent 
it from happening but to secure the state file itself.

---

## The Fix: AWS Secrets Manager

The correct pattern for secrets in Terraform is to store them 
in AWS Secrets Manager and fetch them at apply time using a 
data source.

First create the secret manually. Never through Terraform:
```powershell
aws secretsmanager create-secret `
  --name "prod/db/credentials" `
  --secret-string file://secret.json `
  --region us-east-1
```

Then fetch it at runtime:
```hcl
data "aws_secretsmanager_secret" "db_credentials" {
  name = "prod/db/credentials"
}
```
```hcl
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}
```
```hcl
locals {
  db_credentials = jsondecode(
    data.aws_secretsmanager_secret_version.db_credentials.secret_string
  )
}
```

The secret is fetched at runtime. It never exists in any `.tf` 
file. I proved this by searching all configuration files after 
deployment:

<img width="358" height="16" alt="image" src="https://github.com/user-attachments/assets/01e65b38-dc66-4d9c-8d68-969a3e2aa316" />


No results. The password is nowhere in the codebase.

---

## sensitive = true ; What It Does and Does Not Do

Terraform has a `sensitive = true` flag for variables and outputs. 
It is useful but widely misunderstood.
```hcl
variable "db_password" {
  type      = string
  sensitive = true
}

output "db_connection_string" {
  value     = "mysql://${aws_db_instance.example.endpoint}"
  sensitive = true
}
```

What it does: It hides the value in terminal output and logs. 
Instead of showing the actual value Terraform shows 
`(sensitive value)`:

<img width="187" height="25" alt="image" src="https://github.com/user-attachments/assets/d0c8ed0e-b764-4d83-8124-748ba22c95d9" />


What it does NOT do: It does not prevent the value from being 
stored in the state file. The secret is still there in plaintext. 
`sensitive = true` is about protecting your terminal output and 
CI/CD logs, not your state file.

---

## Securing the State File

Since secrets end up in state regardless, the state file itself 
must be locked down. My S3 backend has all of these in place:
```hcl
terraform {
  backend "s3" {
    bucket         = "grace-terraform-state-2026"
    key            = "day13/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

`encrypt = true` enables AES-256 server-side encryption. The 
bucket also has versioning enabled, block public access turned 
on, and IAM policies restricting access to only the roles that 
run Terraform.

---

## The .gitignore You Always Need

Every Terraform project needs this in `.gitignore`:
```
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.backup
*.tfvars
override.tf
crash.log
```

`*.tfstate` and `*.tfstate.backup` contain secrets in plaintext 
and must never be committed. `*.tfvars` files often contain 
secret values passed as variables. `.terraform/` contains 
downloaded providers that should never be in source control.

---

## What Day 13 Taught Me

Security in Terraform is not one thing; it is a chain. You 
close the hardcoding leak. You close the default value leak. 
You secure the state file. You add the right `.gitignore`. 
You use Secrets Manager. Every link in the chain matters 
because one weak link is all it takes.

The state file lesson hit hardest. I did everything right, no hardcoding, no defaults, secrets fetched from Secrets Manager 
at runtime, and the password was still sitting in plaintext in 
the state file. That is not a failure of the approach. That is 
just how Terraform works. The lesson is that securing the state 
file is not optional. It is the last line of defence.

Day 14, let's go.
