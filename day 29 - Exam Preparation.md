# Fine tuning My Terraform Exam Prep with Practice Exams

Today was one of the most important days in my preparation journey. I completed Practice Exams 3 and 4, but more importantly, I used the results from all four exams to get a clear and honest picture of where I actually stand.

I approached both exams under strict exam conditions. I set a 60 minute timer, answered all 57 questions without referring to any material, and forced myself to rely only on what I truly understand. After each exam, I immediately reviewed my wrong answers while my reasoning was still fresh.

## My Four Exam Performance

Here is how I performed across the two days

Exam 1 Day 28  
50 out of 57, which is 88 percent  

Exam 2 Day 28  
52 out of 57, which is 91 percent  

Exam 3 Today  
49 out of 57, which is 86 percent  

Exam 4 Today  
51 out of 57, which is 89 percent  

What stood out to me is that all my scores are above the 70 percent passing mark, which is reassuring. However, I noticed a slight inconsistency. I am not failing, but I am not perfectly stable either. That told me something important. I understand most of the material, but a few concepts are still not fully solid under pressure.

## What My Mistakes Revealed

After comparing wrong answers across all four exams, I stopped treating mistakes as isolated incidents. Any topic that appeared more than once became a confirmed gap.

One major area was the difference between Terraform state and real infrastructure. I had already struggled with this on Day 28, and it showed up again. Running commands helped me finally lock this in. When I use terraform state rm, I am only removing the resource from Terraform state, not deleting it from the actual cloud environment.

Another repeated gap was terraform import. I kept assuming it helps generate configuration. It does not. It only brings existing resources into state. If my configuration does not match, terraform plan will still show differences.

Workspaces also came up again. I had to clearly separate CLI workspaces from Terraform Cloud workspaces in my mind. Each CLI workspace has its own state file, and they are completely isolated from each other.

Version constraints were another subtle but important gap. I now clearly understand that ~> 1.0 allows updates up to but not including 2.0, while ~> 1.0.0 is stricter and only allows patch level updates.

State locking was the last recurring issue. I initially thought locking applies broadly, but now I understand it mainly prevents concurrent apply operations, not every command.

## Hands On Fixes That Made the Difference

Instead of rereading documentation, I forced myself to run real commands.

I created a simple Terraform resource and practiced state commands. I listed resources, inspected them, removed them from state, and confirmed the behavior step by step. Seeing the separation between state and real infrastructure in action made everything click.

I also worked with workspaces by creating multiple environments, switching between them, and deleting one. This reinforced how Terraform isolates environments using separate state files.

These hands on exercises were far more effective than just reading about the concepts.

## Where I Stand Now

Based on four full practice exams, I consider myself nearly ready. My scores are consistently high, but the small fluctuations show that I still need one more focused review to eliminate uncertainty.

## Final Focus Before the Exam

Going into the final day, I am prioritizing the areas that have repeatedly challenged me

The exact difference between terraform state rm and terraform destroy  
How terraform import interacts with configuration and state  
Workspace behavior and differences between CLI and Terraform Cloud  
Version constraint syntax and interpretation  
State locking behavior and when it applies  

## Reflection

What I realized today is that preparation is not about how many questions I can answer, but how well I understand why I get things wrong. The patterns in my mistakes were more valuable than the scores themselves.

One day left. This is now about refining, not learning from scratch.
