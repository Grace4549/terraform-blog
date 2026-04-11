# My Final Preparation for the Terraform Associate Exam

*Day 24 of the 30-Day Terraform Challenge*

---

No new infrastructure today. No terraform apply. No AWS console.

Just me, a timer, 57 questions, and a very honest conversation with myself about what I actually know versus what I think I know.

---

## I Scored 86% and Still Learned Something

I sat down, set the timer for 60 minutes, and worked through the full simulation without pausing or looking anything up. Flagged the ones I was unsure about, finished the rest, came back to the flagged ones.

Final score: 49/57. (86%)

Passing is 70% so technically I am ready. But the questions I got wrong humbled me. They were not the hard conceptual ones — they were the precise edge case ones. The ones where I knew the general idea but could not nail the exact behaviour fast enough under pressure.

That gap between "I understand this" and "I can answer a question about this in 60 seconds" is real and it is sneaky.

---

## The Things That Tripped Me Up

I thought I knew terraform import. I did; conceptually. What I kept forgetting under pressure is that import does not generate your configuration file. You have to write the resource block yourself before you run the import command. Import only updates state. I knew this. I still second-guessed myself on the question.

The other one that got me was the Terraform Cloud run order. I knew Sentinel runs before apply. I forgot that cost estimation runs between plan and Sentinel. The full order is Plan → Cost Estimation → Sentinel → Apply. One question. One mark. Easily preventable.

And then there is prevent_destroy; which sounds like it prevents terraform destroy but does not. It only blocks destruction during replacement operations. terraform destroy bypasses it completely. I have written this lifecycle block myself. I still hesitated on the question.

These are not knowledge gaps. They are precision gaps. And precision is what the exam actually tests.

---

## What 24 Days of Building Gave Me

Here is what I did not expect going into today's simulation: the questions about real infrastructure felt easy.

ASGs, ALBs, state locking, remote backends, S3 buckets, VPCs; when those came up I did not have to think. I have built all of those things. I have watched them fail. I have debugged them. I have destroyed and rebuilt them. They are not abstract concepts to me anymore.

That is the advantage this challenge gave me that no study guide could. When the exam describes a scenario involving a load balancer and an auto scaling group, I am not imagining it. I am remembering it.

---

## My Exam Day Plan

I wrote this out and I am sticking to it:

Maximum 75 seconds per question - I'll flag and move on if stuck.

I'll answer every question as there's no penalty for wrong answers.

I'll read the question twice before reading answer choices since the trap is usually in the wording.

I'll eliminate the two most obviously wrong answers first, then choose between the remaining two.

On select TWO questions, selecting one or three marks the whole question wrong, i'll strictly select 2.

I'll reserve final 10 minutes for flagged questions.

---

## What I Used to Prepare

I will link the resources below; the official study guide, the sample questions, and the review tutorial were the three I kept coming back to. The sample questions especially. They are the closest thing to the real exam and doing them timed tells you things about your preparation that reading never will.

https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-study-004

https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-review-004

https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-questions-004


---

## Honest Reflection

24 days ago I could not have told you what terraform.tfstate.backup was for. I could not have explained the difference between terraform state rm and terraform destroy. I could not have written a Sentinel policy or explained why the plan file is an immutable artifact.

Now I can do all that!


---

*Part of the 30-Day Terraform Challenge by AWS AI/ML UserGroup Kenya, Meru HashiCorp User Group, and EveOps.*

*#30DayTerraformChallenge #TerraformAssociate #Terraform #DevOps #IaC #AWSUserGroupKenya #EveOps*
