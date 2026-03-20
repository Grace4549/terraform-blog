# State Isolation: Workspaces vs File Layouts — When to Use Each

If you've been following my 30-day Terraform challenge, you know that every day comes with its own lessons — and today, Day 7, did not disappoint. Today was all about one question: how do you manage multiple environments like dev, staging, and production without them stepping on each other?

Spoiler: Terraform gives you two answers. And I had to learn both the hard way.

---

## First, Some Context

By this point in the challenge I had already set up remote state in S3 and state locking with DynamoDB. My infrastructure was talking to AWS, my state was safe and things were looking good. Then Day 7 hit me with a new problem: what happens when you need dev, staging, and production all running at the same time without interfering with each other?

That's where state isolation comes in.

---

## Approach 1: Terraform Workspaces

The first approach I tried was Workspaces. The idea is simple — same code, same directory, but each environment gets its own state file. Think of it like having one kitchen but separate shelves for each person's food.

Creating the workspaces was straightforward:

```powershell
terraform workspace new dev
terraform workspace new staging
terraform workspace new production
```

<img width="370" height="73" alt="image" src="https://github.com/user-attachments/assets/1cbf9774-1721-4479-8467-0e9f02623708" />


The cool part was using `terraform.workspace` inside my configuration to make things dynamic. The same code would behave differently depending on which workspace was active:

```hcl
variable "instance_count" {
  type = map(number)
  default = {
    dev        = 2
    staging    = 2
    production = 1
  }
}

resource "aws_instance" "app" {
  count         = var.instance_count[terraform.workspace]
  instance_type = var.instance_type[terraform.workspace]
  tags = {
    Name        = "web-${terraform.workspace}"
    Environment = terraform.workspace
  }
}
```

Production got 1 instance, dev and staging got 2 each. The naming was automatic. It felt elegant. Then I tried to apply to production and things got interesting.

---

## The Problems Started

After that, production finally came up, but not before hitting the AWS VPC limit of 5 (free-tier). I had leftover VPCs from previous days just sitting there. Then the vCPU limit. 
One thing after another. But each error taught me something.

<img width="505" height="74" alt="image" src="https://github.com/user-attachments/assets/2ce4817c-8465-4616-9759-aa242f005264" />


---

## Approach 2: File Layout Isolation

Once I had workspaces working, I moved on to the second approach — File Layout isolation. This is where things clicked for me.

Instead of one directory with one set of files, you create a completely separate directory for each environment. Each one has its own code, its own backend configuration, and its own state file in S3.

<img width="398" height="421" alt="image" src="https://github.com/user-attachments/assets/79d3137b-7d4f-4b12-819b-da378b6115f8" />


Each environment has its own `backend.tf` pointing to a unique state file path in S3. The only thing that changes between them is the `key`:

```hcl
# dev
key = "environments/dev/terraform.tfstate"

# production
key = "environments/production/terraform.tfstate"
```

You navigate into each directory and run `terraform init` and `terraform apply` independently. There is no shared code. No `terraform.workspace`. No risk of forgetting which environment you are on.

<img width="938" height="365" alt="image" src="https://github.com/user-attachments/assets/68b3ee69-a918-4332-a9d8-e9e9a494f795" />


Seeing those three completely separate state files in S3 was genuinely satisfying.

---

## The Remote State Data Source

The last piece was connecting environments together using `terraform_remote_state`. The problem it solves is this — what if your app layer needs to know the VPC ID created by your networking layer? Instead of hardcoding the ID, you read it directly from the other environment's state file:

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "grace-terraform-state-2026"
    key    = "environments/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

output "dev_vpc_id" {
  value = data.terraform_remote_state.network.outputs.vpc_id
}

output "dev_subnet_id" {
  value = data.terraform_remote_state.network.outputs.subnet_id
}
```

After applying, my app environment printed out the exact VPC ID and subnet ID from dev — without me typing a single ID manually.

<img width="424" height="88" alt="image" src="https://github.com/user-attachments/assets/702675b6-0f93-4956-9a91-d1dc07b5ef14" />


---

## So Which One Should You Use?

Here is my honest take after implementing both:

| | Workspaces | File Layout |
|---|---|---|
| Code isolation |  Shared |  Separate |
| Wrong env risk |  High |  Low |
| Team scalability |  Poor |  Good |
| Production use |  No |  Yes |

Workspaces are convenient for quick experiments or when you are working alone and just need to test something fast. But in a team environment, or anywhere production is involved, file layout wins every time.

The reason is simple: with workspaces, one wrong command in the wrong workspace can affect production. With file layout, you have to physically be in the production directory to touch production. That friction is a feature, not a bug.

---

## What Day 7 Taught Me

State isolation is not just a technical concept. It is a discipline. The tools Terraform gives you are only as safe as the habits you build around them. Today I broke things, hit limits, cleaned up messes, and rebuilt. And now I genuinely understand why experienced teams choose file layout for production.

If you are just starting out with Terraform, do not skip this. The day you accidentally apply to production when you meant to apply to dev is the day you will wish you had set up file layout isolation from the beginning. Learn it now, thank yourself later.
