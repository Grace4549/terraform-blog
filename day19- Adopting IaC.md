# How to Convince Your Team to Adopt Infrastructure as Code

Day 19 of the 30-Day Terraform Challenge and today there was
no code to write. No AWS resources to deploy. No errors to debug.

Today was about something harder than all of that.

---

## The Real Challenge of IaC

Here is something nobody tells you when you start learning
Terraform: the technical part is the easy part.

You can spend 18 days mastering modules, state management,
secrets handling and automated testing. You can build
production-grade infrastructure that passes every test.
And then you walk into a team meeting and someone says
"why can't we just use the console like we always have?"

And you realise the real work has not even started yet.

Adopting Infrastructure as Code is a people problem as much
as it is a technical one. It requires changing how a team
thinks about infrastructure. From something you click
into existence to something you code, review and deploy
like software. That shift does not happen overnight and
it does not happen just because you showed someone a
Terraform tutorial.

---

## Why Most IaC Adoptions Fail

Most IaC adoptions fail because teams try to do too much too fast.

They announce a full migration. They stop other work. They
spend three months rewriting every piece of existing
infrastructure in Terraform. And by the time they finish,
if they finish, the business has moved on, engineers are
burned out and leadership has lost patience.

The irony is that the goal was good. The approach was wrong.

---

## The Incremental Strategy

The alternative is deceptively simple: start with something new.

Do not migrate existing infrastructure first. Pick one new
resource like a new S3 bucket, a new IAM role, a new monitoring
dashboard, and provision it entirely with Terraform. Get it
reviewed. Get it merged. Get it deployed.

That one success story is worth more than any presentation.
It proves the workflow works. It gives team members something
real to look at. And it creates zero migration risk because
nothing existing was touched.

From there, you expand, one resource at a time, one success
at a time, until the team is comfortable enough to start
importing existing infrastructure using `terraform import`.
```
terraform import aws_s3_bucket.state_bucket grace-terraform-state-2026
```

`terraform import` brings an existing manually-created resource
under Terraform management without recreating it. Today I
imported the S3 state bucket and DynamoDB lock table that were
created manually on Day 6, two resources that Terraform has
been using for weeks but never actually managed.

After importing you write the matching resource block and run
`terraform plan` to confirm no changes are needed. When the
plan comes back clean it means Terraform's understanding of
the resource perfectly matches reality.

<img width="836" height="404" alt="image" src="https://github.com/user-attachments/assets/e4393d22-2913-424b-9091-41a17cc551bf" />


---

## The Business Case

If you need to convince leadership, do not talk about Terraform.
Talk about outcomes.

| Problem | Solution | Outcome |
|---|---|---|
| Incidents from manual errors | Code review before apply | Fewer production incidents |
| Hours on repetitive setup | Reusable modules | Engineering time freed |
| No audit trail | Every change is a git commit | Full compliance trail |
| Dev differs from production | Identical configs | Fewer environment bugs |

Every item in that table is something a manager or executive
cares about. None of them requires understanding what a
Terraform module is.

---

## The Four Phases

A realistic adoption plan has four phases, each small enough
to show results within 2-4 weeks:

**Phase 1** - Provision one new thing with Terraform. Zero
migration risk. One success story.

**Phase 2** - Import critical existing resources one at a time.
Start with what changes most often or has caused incidents.

**Phase 3** - Establish team practices. Code review for all
infrastructure changes. No manual console changes to
Terraform-managed resources. Ever.

**Phase 4** - Automate deployments. Merges to main trigger
`terraform apply`. Infrastructure changes go through the
same pipeline as application code.

Each phase builds on the last. Each one produces something
real that the team can see and trust.

---

## The Habit That Changes Everything

The hardest part of IaC adoption is not the technology.
It is the habit change.

The console is immediate and visual. You click, things appear.
Terraform requires writing code, running plan, reviewing output
and applying. That extra friction feels like overhead, until
the first time a code review catches a mistake that would have
caused a production incident.

That moment changes everything. Suddenly the friction is not
overhead. It is protection.

---

## What Day 19 Taught Me

Nineteen days of building infrastructure taught me how to
use Terraform. Today taught me how to make it matter beyond
my own terminal.

The engineers who drive real change in organisations are not
just technically skilled. They understand people. They make
incremental progress. They build trust before asking for it.

The technical foundation is there. The rest is how you
use it.

Day 20, let's go.

#30DayTerraformChallenge #TerraformChallenge #Terraform #IaC
#DevOps #PlatformEngineering #HashiCorp #CloudComputing
#LearningInPublic #100DaysOfCloud #AWSUserGroupKenya #EveOps
