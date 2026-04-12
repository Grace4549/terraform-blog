# Deploying a Static Website on AWS S3 with Terraform

Day 25 of the 30-Day Terraform Challenge and today I built
something I can actually show people.

Not a VPC. Not an IAM role. Not a DynamoDB lock table. A real
website. Live on the internet. Globally distributed. Deployed
entirely through code.

---

## What We Built

A static website hosted on AWS S3 and delivered through
CloudFront: Amazon's global content delivery network.

S3 stores the files. CloudFront serves them from servers
closest to whoever is visiting. So someone in Nairobi gets
the same fast experience as someone in New York. It also
handles HTTPS automatically. No certificate management.
No manual configuration.

The whole thing is deployed through Terraform. No AWS console.
No clicking. Just code.

---

## The Project Structure

The first decision was structure. Following the module pattern
from Days 8 and 9 everything is split into two parts:
modules/s3-static-website/   ← the blueprint
envs/dev/                    ← the deployment

The module contains all the complexity: S3 bucket, website
configuration, public access settings, bucket policy,
CloudFront distribution and the HTML files themselves.

The dev environment contains almost nothing:

```hcl
module "static_website" {
  source      = "../../modules/s3-static-website"
  bucket_name = var.bucket_name
  environment = var.environment
}
```

That is it. Seven lines. The module does the rest.

If I wanted to add staging tomorrow, it would be one new folder
with the same seven lines and different values. That is the
DRY principle working exactly as intended.

---

## The Infrastructure

Three AWS resources do the real work:

**S3 bucket**: stores index.html and error.html. Configured
for static website hosting with public read access via a
bucket policy.

**CloudFront distribution**: sits in front of S3 and serves
the files from 400+ edge locations globally. Redirects HTTP
to HTTPS automatically. Caches files for up to 24 hours
so S3 is not hit on every request.

**S3 objects**: the actual HTML files uploaded directly by
Terraform. No manual file upload needed.

The `force_destroy = true` on the bucket is a practical
detail worth knowing — by default Terraform refuses to destroy
an S3 bucket that contains files. `force_destroy` overrides
this for dev environments where cleanup should be easy.

---

## Deployment

```powershell
cd envs\dev
terraform init
terraform apply -auto-approve
```

<img width="665" height="161" alt="image" src="https://github.com/user-attachments/assets/7688572b-57bb-473b-9449-02de30a90b53" />


CloudFront takes 5-15 minutes to propagate globally after
creation. Then:

<img width="369" height="185" alt="image" src="https://github.com/user-attachments/assets/70040c9e-c051-4a3e-aa50-bbbac94e1bab" />


A real website. Live. Served over HTTPS. Deployed from a
terminal. No console clicks.

---

## What This Project Proves

Every best practice from the last 24 days showed up today:

Modules - all complexity in one reusable place.
Remote state - S3 backend with DynamoDB locking.
DRY configuration - one module, infinite environments.
Consistent tagging - common_tags on every resource.
Input validation - environment variable rejects invalid values.
Variable defaults - sensible defaults where they make sense,
no defaults where they do not.

This is what production-grade Terraform looks like in practice.
Not any one of these things but all of them together.

---

## Cleanup

CloudFront distributions cost money even when idle. I destroyed
immediately after confirming it worked:

```powershell
terraform destroy -auto-approve
```

<img width="337" height="20" alt="image" src="https://github.com/user-attachments/assets/77d2cff0-50bc-4bcb-9baa-001fd59b87b7" />


Clean. No orphaned resources. No surprise charges.

---

## What Day 25 Taught Me

Twenty-five days ago I was learning what a provider was.
Today I deployed a globally distributed website using a
reusable module, remote state, environment isolation and
automated HTML file management - all in one terraform apply.

The distance between Day 1 and Day 25 is significant.
The distance between Day 25 and production-ready is smaller
than I expected.
