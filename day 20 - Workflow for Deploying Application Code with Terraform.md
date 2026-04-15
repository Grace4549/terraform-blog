# A Workflow for Deploying Application Code with Terraform - Day 20

*Day 20 of the 30-Day Terraform Challenge*

---

Let me paint you a picture.

Sarah needs to update the web server. She opens her laptop, runs `terraform apply` from her Downloads folder, using her personal AWS keys. It works. Two weeks later, Sarah is on leave. The server breaks. Nobody knows what she did. The state file is on her laptop. The team is stuck.

This is not a horror story I made up. This is Tuesday for teams that skip the deployment workflow.

Today, I built the system that stops Tuesday from happening.

---

## The Seven Steps - And Why Each One Exists

Software teams figured this out years ago. You write code, push to Git, open a pull request, run tests, get a review, merge, and deploy. Every step exists because someone skipped it once and paid for it.

Terraform lets you apply the same discipline to cloud infrastructure. Here is how I walked through all seven steps today using my webserver cluster.

---

### Step 1: Version Control

My Terraform files live in GitHub. Main branch is protected, and nobody pushes directly to it. Every change goes through a pull request.

The critical difference from application code: the state file does NOT go in Git. It lives in Terraform Cloud. If two engineers apply from different state files, they create duplicate resources or destroy each other's work. Remote state with locking prevents that entirely.

---

### Step 2: Run Locally

You cannot run infrastructure on your laptop the way you run `npm start`. But you can preview every change before it touches AWS:

```bash
terraform plan -out=day20.tfplan
```

This shows you exactly what will change - how many resources will be created, modified, or destroyed. I saved the plan to a file. This matters more than it sounds.

The gap between `terraform plan` and `terraform apply` is dangerous. If someone else changes infrastructure in that gap, a fresh apply picks up their change too - unreviewed. A saved plan file applies exactly what was reviewed. Nothing more.

---

### Step 3: Make the Code Change

Created a feature branch:

```bash
git checkout -b update-app-version-day20
```

Updated the HTML response in my webserver's user data script from the base version to v3. One line change. Committed, pushed to the branch.

The change itself is simple. The discipline around it is the point.

---

### Step 4: Submit for Review

I opened a pull request and pasted the full `terraform plan` output in the description. This is the infrastructure equivalent of a code diff.

Here is why this matters: a one-line change in a `.tf` file can look innocent but hide a plan that destroys your entire database. The plan output shows the reviewer exactly what will happen in AWS - down to every single resource, without them running anything themselves.

My reviewer could see: 1 resource to modify, 0 to destroy. Safe to merge.

---

### Step 5: Automated Tests

GitHub Actions triggered automatically on the pull request. The workflow ran `terraform validate`, `terraform fmt`, and `terraform test`.

I hit my first snag here - the unit tests had no AWS credentials. I fixed by adding `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as GitHub secrets and wiring them into the workflow. Tests went green. 

This step exposed something important: infrastructure tests need real AWS credentials and deploy real resources. You cannot run them freely on every commit the way you run unit tests. You make tradeoffs.

---

### Step 6 - Merge and Tag

I merged the pull request and tagged the release:

```bash
git tag -a "v1.3.0" -m "Update app response to v3"
git push origin v1.3.0
```

Tags matter. If your module is consumed by other teams, they need to pin to a stable version. Without tags, they get whatever is on main today, which might break their infrastructure tomorrow.

---

### Step 7: Deploy

I applied the saved plan:

```bash
terraform apply day20.tfplan
```

14 resources created. Then tested the live endpoint:

```bash
curl http://<alb-dns>
Hello from webserver-cluster - dev - v3
```

v3 live. Workflow complete.

---

## Terraform Cloud - The Trusted Environment

Without Terraform Cloud, teams hit four walls: state on laptops gets lost, AWS keys on machines leak, there is no audit log, and no access controls. Anyone can apply anything from anywhere.

Terraform Cloud solves all four. I migrated my state from local to Terraform Cloud with a single `terraform init`. My AWS credentials now live as sensitive workspace variables - encrypted, never shown in logs, injected only at apply time.

Nobody's laptop holds keys anymore.

<img width="419" height="327" alt="image" src="https://github.com/user-attachments/assets/72b86959-1b62-459c-9ded-a0226e1fd93d" />


<img width="374" height="167" alt="image" src="https://github.com/user-attachments/assets/de999211-c30c-46cb-a935-24c1320c4ec3" />



---

## Private Registry - Modules Your Team Can Actually Trust

I published my webserver cluster module to the Terraform Cloud private registry. The naming convention `terraform-aws-webserver-cluster` is required. That is how Terraform Cloud identifies it as a module. Tagged `v1.0.0`, connected the repo, published.

Now any team member can reference it like a public module:

```hcl
module "webserver_cluster" {
  source  = "app.terraform.io/your-org/webserver-cluster/aws"
  version = "1.0.0"
}
```

Versus a raw GitHub URL that gives you no versioning, no docs, and no stability guarantee. The private registry is the difference between a module and a reliable, versioned library.

<img width="371" height="308" alt="image" src="https://github.com/user-attachments/assets/05f68c5b-9147-4238-94a0-f5d928a23339" />

---

## The Biggest Insight

Infrastructure as Code only works when you treat it like code all the way through. The workflow is not bureaucracy. Each step exists because a team skipped it once and paid a painful price.

The plan review catches the accidental database deletion. The version tag saves the team when main breaks. The trusted apply environment keeps credentials off laptops.

Skip any step and you are back to Sarah's state file sitting on a laptop somewhere, and nobody knows where.

20 days in. The discipline is the point.

---

*Part of the 30-Day Terraform Challenge by AWS AI/ML UserGroup Kenya, Meru HashiCorp User Group, and EveOps.*

*#30DayTerraformChallenge #Terraform #TerraformCloud #DevOps #IaC #AWS #AWSUserGroupKenya #EveOps*
