# Preparing for the Terraform Associate Exam: Key Resources and Tips

Day 23 of the 30-Day Terraform Challenge and the gear has shifted.

No new infrastructure today. No deployments. No debugging
session that runs until midnight. Today I sat down with the
official exam study guide (https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-study-004)  and did something uncomfortable; 
I audited myself honestly against every exam domain.

---

## The Audit That Changes Everything

The Terraform Associate exam covers nine domains. The CLI
commands domain alone is 26 percent of the exam. That is more
than a quarter of the entire test on commands you use every
day, without necessarily knowing every flag they carry.

I went through each domain and rated myself green or yellow.

Green - I can explain it and I have done it hands-on.
Yellow - I understand it conceptually but have gaps.

IaC concepts, modules, core workflow - green across the board.
Nineteen days of building real infrastructure does that.

Terraform Cloud - yellow. I have used S3 as a backend since
Day 6 but Terraform Cloud's remote runs, Sentinel policies
and private registry are a different world. That is where
the focused study goes.

CLI commands - yellow. I know the main ones cold but the exam
tests edge cases that catch people off guard.

---

## The CLI Section Is Harder Than You Think

Most people underestimate this section. They know
`terraform init`, `terraform plan`, `terraform apply` and
`terraform destroy`. That is not enough.

The exam asks scenario questions. Not just what does
`terraform state rm` do - but what is the impact on real
infrastructure when you run it?

The answer is nothing. The real resource still exists.
Only Terraform's awareness of it is gone.

Or this one: a team member manually deleted an RDS instance
that Terraform manages. What does the next `terraform plan`
show? It shows the instance as a resource to be created.
Terraform detects the drift and plans to restore what is missing.

These are not trick questions. They test whether you understand
what Terraform actually does - not just the commands but the
mental model behind them.

---

## Non-Cloud Providers: The Ones Nobody Talks About

The exam tests providers that have nothing to do with AWS.
The `random` provider generates unique values. The `local`
provider creates files. I built both today:

```hcl
resource "random_id" "suffix" {
  byte_length = 4
}

resource "local_file" "config" {
  content  = "cluster_id = ${random_id.suffix.hex}"
  filename = "${path.module}/config.txt"
}
```


<img width="449" height="118" alt="image" src="https://github.com/user-attachments/assets/d1730963-75af-463f-917c-584df30d885e" />



Where are these useful in real configurations? The `random`
provider solves the global uniqueness problem for S3 bucket
names. The `local` provider generates configuration files
that other tools need to consume. Simple, practical and
worth knowing cold before exam day.

---

## Writing Your Own Practice Questions

One of the most effective exam prep techniques is writing
your own questions. It forces you to understand the material
well enough to construct a plausible wrong answer.

Here is one I wrote based on Day 15 of this challenge:

You have a module that needs to deploy resources in two AWS
regions. What must the module declare to accept provider
aliases from its caller?

A) Two separate provider blocks inside the module
B) configuration_aliases in the required_providers block
C) A providers variable of type map
D) A region variable for each provider

Answer: B. Writing that question took 10 minutes.
Understanding it well enough to write it took 15 days of
hands-on work.

---

## The Study Plan

Based on the audit I built a concrete study plan covering
every yellow area with specific methods and time estimates.
Not "review state management" - but "run terraform state mv
and terraform state rm against a test resource and write
three practice questions about what each one does to real
infrastructure."

Vague study plans produce vague results. Specific ones produce
passing scores.

---

## What Day 23 Taught Me

The difference between someone who has built infrastructure
for 22 days and someone who is ready to pass the associate
exam is smaller than you think. The hands-on work is the
foundation. The exam preparation is filling in the edges.

CLI edge cases. Terraform Cloud capabilities. State management
nuances. These are learnable in a week if the foundation
is solid.

Mine is. Time to fill in the edges.

#30DayTerraformChallenge #TerraformChallenge #Terraform
#TerraformAssociate #CertificationPrep #DevOps #IaC
#HashiCorp #LearningInPublic #100DaysOfCloud
#AWSUserGroupKenya #EveOps
