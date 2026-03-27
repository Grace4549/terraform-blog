# Day 14: Working with Multiple Providers

Today was one of those “aha!” Terraform days   
I moved from single-region setups to **multi-region infrastructure** using provider aliases. And honestly, it’s much cleaner than it sounds.

Let’s break it down 

---

## main.tf

```hcl
terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket         = "grace-terraform-state-2026"
    key            = "day14/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default provider → us-east-1
provider "aws" {
  region = "us-east-1"
}

# Aliased provider → us-west-2
provider "aws" {
  alias  = "us_west"
  region = "us-west-2"
}

# IAM role for replication
resource "aws_iam_role" "replication" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
    }]
  })
}

# IAM policy for replication
resource "aws_iam_role_policy" "replication" {
  role = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetReplicationConfiguration","s3:ListBucket"]
        Effect   = "Allow"
        Resource = aws_s3_bucket.primary.arn
      },
      {
        Action   = ["s3:GetObjectVersionForReplication","s3:GetObjectVersionAcl","s3:GetObjectVersionTagging"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.primary.arn}/*"
      },
      {
        Action   = ["s3:ReplicateObject","s3:ReplicateDelete","s3:ReplicateTags"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.replica.arn}/*"
      }
    ]
  })
}

# Primary bucket → default provider (us-east-1)
resource "aws_s3_bucket" "primary" {
  bucket = "grace-primary-bucket-day14"
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Replica bucket → aliased provider (us-west-2)
resource "aws_s3_bucket" "replica" {
  provider = aws.us_west
  bucket   = "grace-replica-bucket-day14"
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.us_west
  bucket   = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Replication config
resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket = aws_s3_bucket.replica.arn
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.replica
  ]
}
```
## Explanation

This is where the magic happens 

The default provider handles everything in us-east-1
The aliased provider (aws.us_west) handles us-west-2
Terraform uses the default automatically, unless you override it
The provider argument is what forces a resource into another region

Add in IAM + versioning, and cross-region replication works!

## outputs.tf
```
output "primary_bucket_name" {
  value = aws_s3_bucket.primary.bucket
}

output "primary_bucket_region" {
  value = aws_s3_bucket.primary.region
}

output "replica_bucket_name" {
  value = aws_s3_bucket.replica.bucket
}

output "replica_bucket_region" {
  value = aws_s3_bucket.replica.region
}

output "replication_role_arn" {
  value = aws_iam_role.replication.arn
}
```
## Explanation

These outputs are your quick validation 

Confirm both buckets exist
Confirm they are in different regions
Confirm replication role is created

If this looks good then your infra is working.

## What I Did
Ran terraform init - This downloaded provider + initialized backend
Ran terraform plan and saw resources in both regions
<img width="521" height="134" alt="image" src="https://github.com/user-attachments/assets/07b31f3a-5819-4eb3-81be-0681b7cda002" />


Ran terraform apply - this deployed everything
<img width="601" height="130" alt="image" src="https://github.com/user-attachments/assets/1a1af7d2-18ee-42eb-bffe-12bd816c8b85" />


Ran terraform output to see verified regions

<img width="566" height="98" alt="image" src="https://github.com/user-attachments/assets/e8878475-ccfd-4d30-a186-c5c471138ee7" />



Checked AWS Console → confirmed both buckets
<img width="672" height="26" alt="image" src="https://github.com/user-attachments/assets/c30d4364-fd54-438d-91df-f0ce1849365b" />

<img width="680" height="29" alt="image" src="https://github.com/user-attachments/assets/2ead81b3-1007-40de-b78f-9db8d214ac82" />



## Key Learnings

Providers = these  bridge between Terraform and cloud APIs

Aliases = how you scale across regions/accounts

Terraform always uses a provider (default or explicit)

.terraform.lock.hcl keeps everything consistent

Multi-region setups are actually simple once you understand providers

## Final Thoughts

Before today, multi-region felt complex.
Now? It’s just one extra provider block and one line per resource.

That’s the power of Terraform.
