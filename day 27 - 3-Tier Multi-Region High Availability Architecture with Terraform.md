# Building a 3-Tier Multi-Region High Availability Architecture with Terraform - Day 27

*Day 27 of the 30-Day Terraform Challenge*

---

In 2011, AWS had a major outage in us-east-1. A lot of companies went down that day. Netflix stayed up.

Not because they were lucky. Because they had deliberately engineered their systems to survive a complete regional failure. They called the discipline chaos engineering. The rest of the industry called it impressive and then quietly started rebuilding their own infrastructure.

Today I built that kind of system. Not for Netflix — for a 30-day challenge. But the architecture is identical in principle, and understanding how it works is the kind of thing that genuinely separates junior engineers from senior ones.

---

## The Problem Nobody Talks About in Job Interviews

When companies ask about high availability in interviews, most candidates talk about load balancers. Maybe auto scaling. The good ones mention availability zones.

Almost nobody mentions regions.

A load balancer distributes traffic across servers. An auto scaling group replaces unhealthy servers automatically. These protect you from individual server failures and AZ failures.

They do not protect you from us-east-1 going dark.

When a full region fails, and AWS regions have failed more than once, everything in that region goes with it. Your servers, your load balancer, your database. All of it. Unless you planned for it.

Today I planned for it.

---

## Five Modules. Two Regions. One Apply.

The architecture has five layers expressed as separate Terraform modules:

**VPC** - the network foundation in each region. Public subnets for the load balancer, private subnets for the database. Two availability zones per region so even a single AZ failure within a region does not take anything down.

**ALB** - the traffic director. Sits in front of the application servers, distributes requests, removes unhealthy instances within 30 seconds of a health check failure.

**ASG** - the compute layer. EC2 instances that scale up when CPU is high and scale down when traffic drops. Each instance reports its region and availability zone in the response — so you can see exactly which part of the world is serving your request.

**RDS** - the database. Primary instance in us-east-1 encrypted at rest. Cross-region replica architecture designed and documented — not deployed on free tier because AWS requires paid backup retention for cross-region replication. This is a real constraint that real teams navigate.

**Route53** - the DNS intelligence layer. Health checks polling both regions every 30 seconds. Primary region fails three consecutive checks? DNS automatically shifts all traffic to the secondary. Designed and documented — not deployed without a registered domain. The code exists. The architecture is real.

<img width="660" height="107" alt="image" src="https://github.com/user-attachments/assets/09f7fb71-36d2-4c40-b105-2ff1d7cf9800" />


---

## What Makes This Actually Production-Grade

The detail that most tutorials skip is the security boundary between tiers.

It would be easier to open port 80 on every resource to the entire internet and call it working. That is what most demos do.

This architecture does something different. The EC2 instances only accept traffic from the ALB security group - not from the internet directly. The RDS instance only accepts connections from the EC2 instance security group - not from anywhere else.

Three tiers. Three security walls. Even if someone compromised the load balancer, they would hit a second wall at the application tier. Even if they compromised an EC2 instance, they would hit a third wall at the database.

This is defence in depth. And it is expressed in Terraform as outputs flowing between modules:

```hcl
module "asg_primary" {
  alb_security_group_id = module.alb_primary.alb_security_group_id
}

module "rds_primary" {
  app_security_group_id = module.asg_primary.instance_security_group_id
}
```

The ALB's security group ID flows into the ASG. The ASG's security group ID flows into the RDS. Infrastructure security as code. Reviewable, version controlled, reproducible.

<img width="585" height="131" alt="image" src="https://github.com/user-attachments/assets/c9baabe9-675c-4114-942a-77b15ab264e9" />


<img width="638" height="125" alt="image" src="https://github.com/user-attachments/assets/dc1abc27-03b7-49e0-aefc-d0aaf31b87fb" />


---

## The Distinction That Actually Matters

Multi-AZ and cross-region replicas solve different problems. Most engineers confuse them.

**RDS Multi-AZ** keeps you running when an availability zone fails. AWS maintains a synchronous standby in a different AZ. Failover is automatic and completes in about 90 seconds. No data loss because every write is confirmed on both before being acknowledged.

**Cross-region read replica** keeps you running when an entire region fails. Replication is asynchronous — the replica may be slightly behind. Promotion to primary requires manual intervention. There may be seconds of data loss depending on replication lag.

Multi-AZ is high availability. Cross-region replica is disaster recovery. Both matter. They are not the same thing.

<img width="895" height="281" alt="image" src="https://github.com/user-attachments/assets/35709b3f-c012-4fae-bbaa-3a2171c2b0d9" />


<img width="916" height="262" alt="image" src="https://github.com/user-attachments/assets/74f5e138-ff6a-4ff0-a36f-83637dc6fccb" />


<img width="935" height="280" alt="image" src="https://github.com/user-attachments/assets/4a6544bf-5310-4017-a785-0d2a43cb69fc" />


---

## What Failover Actually Looks Like

This is the timeline of a regional outage with this architecture:

0:00 - us-east-1 goes dark. Primary ALB stops responding.

0:30 - First failed Route53 health check.

1:00 - Second failed health check.

1:30 - Third failed health check. Route53 updates the DNS record to point to us-west-2.

1:30 to 2:30 - DNS TTL expires for existing clients. They pick up the new record.

2:30 - All traffic flowing to us-west-2. Users experienced roughly 90 seconds of degraded service. Most never noticed.

That 90 seconds of automatic failover with zero human intervention is the difference between a company that survives a regional outage and one that has an all-hands incident call at 3am while the CEO watches the revenue counter go to zero.

---

## What Free Tier Taught Me About Real Constraints

Here is something tutorials never tell you: real infrastructure engineering is full of constraints that have nothing to do with the technology.

AWS free tier does not allow backup retention on RDS. Cross-region replication requires backup retention. So on a free tier account, you cannot deploy a cross-region RDS replica.

Real teams face this constantly. Budget constraints. Compliance requirements. Organisational policies. The ability to design around constraints — to know the architecture, document it clearly, and implement what is possible within the current limitations - is an actual engineering skill.

I designed the full architecture. Deployed what free tier allows. Documented what it does not. The code for the replica module exists. The architecture is understood. That is not a limitation in the learning - that is the learning.

---

## 27 Days In

When I started this challenge I was deploying single EC2 instances in a default VPC.

Today I am deploying infrastructure across two AWS regions simultaneously, with independent compute stacks, security boundaries between every tier, and automatic failover built into the DNS layer.

One terraform apply. Two regions. Everything connected through module outputs and inputs in a dependency chain that Terraform resolves automatically.

Three days left. This is what the last 27 days built toward.

<img width="459" height="26" alt="image" src="https://github.com/user-attachments/assets/35e54210-1293-4682-a6c0-320105b271ba" />


---

*Part of the 30-Day Terraform Challenge by AWS AI/ML UserGroup Kenya, Meru HashiCorp User Group, and EveOps.*

*#30DayTerraformChallenge #Terraform #AWS #HighAvailability #MultiRegion #DevOps #IaC #AWSUserGroupKenya #EveOps*
