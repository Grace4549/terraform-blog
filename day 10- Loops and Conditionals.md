# Mastering Loops and Conditionals in Terraform

Day 10 of the 30-Day Terraform Challenge and today Terraform finally 
started feeling like a real programming language.

Until today every resource I declared was written out individually. 
One user. One block. One line at a time. That works fine until someone 
asks you to create ten IAM users. Or twenty. Or a hundred. Today I 
learned the four tools that make that problem disappear entirely.

---

## The Problem With Writing Everything By Hand

Imagine you need three IAM users. You could write three separate 
resource blocks. Now imagine you need ten. Or the list changes next 
week. That approach falls apart fast and becomes a maintenance nightmare.

Terraform gives you four tools to fix this: `count`, `for_each`, 
`for` expressions and conditionals. Today I used all four, and one 
of them broke things in a very satisfying way.

---

## count - The Simple Loop

`count` is the most straightforward loop. Tell Terraform how many 
copies you want and it creates them using `count.index` as the 
position number.
```hcl
resource "aws_iam_user" "count_users" {
  count = length(var.user_names_count)
  name  = "count-${var.user_names_count[count.index]}"
}
```

I used Grace, Priscillah and Joseph as my test users. Three users, one 
resource block. Clean and simple.

But then I removed Grace from position 0 to test what would happen.

<img width="497" height="223" alt="image" src="https://github.com/user-attachments/assets/d88e2177-7f78-46ba-b781-32f879eb0d07" />


Terraform completely panicked. It tried to rename Priscillah to 
Grace's old slot and Joseph to Priscillah's old slot. Since those 
names already existed in AWS it threw a conflict error. The whole 
apply failed because of one removal from a list.

That is the `count` ordering problem. And it is exactly why `for_each` exists.

---

## for_each - The Safe Loop

`for_each` keys resources on actual values not positions. So when Grace 
is removed, only Grace is destroyed. Priscillah and Joseph are 
completely untouched because their keys never changed.

With a set of names:
```hcl
resource "aws_iam_user" "foreach_users" {
  for_each = var.user_names_foreach
  name     = "foreach-${each.value}"
}
```

With a map carrying additional data per user:
```hcl
resource "aws_iam_user" "map_users" {
  for_each = var.users_map
  name     = "map-${each.key}"

  tags = {
    Department = each.value.department
    Admin      = each.value.admin
  }
}
```

Grace is in engineering and an admin. Priscillah is in DevOps and 
an admin. Joseph is in marketing and not an admin. All of that 
captured in one variable, one resource block.

<img width="650" height="256" alt="image" src="https://github.com/user-attachments/assets/b8d09fad-6227-47d7-a207-46d078c64122" />


`each.key` gives the map key. `each.value` gives the object attached 
to that key. The difference between `count` and `for_each` is not 
just syntax. It is the difference between infrastructure that breaks 
silently and infrastructure that behaves predictably.

---

## for Expressions - Reshaping Data

`for` expressions do not create resources. They transform existing 
data into a more useful shape; inside outputs, locals or anywhere 
you need to reshape a collection.
```hcl
output "foreach_user_arns" {
  value = { for name, user in aws_iam_user.foreach_users : name => user.arn }
}
```

Instead of a list of ARNs I get a clean map of username to ARN. 
Any downstream resource that needs to reference Grace specifically 
can just look up her name instead of guessing her index position. 
Much cleaner, much safer.

---

## Conditionals - Making Resources Optional

The ternary operator combined with `count` is how you make resources 
appear and disappear based on a variable. `count = 1` creates the 
resource. `count = 0` skips it entirely.
```hcl
resource "aws_iam_user" "autoscaling_user" {
  count = var.enable_autoscaling ? 1 : 0
  name  = "autoscaling-service-account"
}
```

I also used `locals` to centralise environment-based instance sizing:
```hcl
locals {
  instance_type = var.environment == "production" ? "t3.medium" : "t3.micro"
}
```

When I set `enable_autoscaling=false` the autoscaling user was 
destroyed and the output showed `autoscaling disabled`:

<img width="428" height="86" alt="image" src="https://github.com/user-attachments/assets/169ee34e-9ade-4a5e-bd6f-7fe7b13f24a2" />



When I set `environment=production` the instance type switched from 
`t3.micro` to `t3.medium` without touching a single resource block:

<img width="581" height="213" alt="image" src="https://github.com/user-attachments/assets/a78ad7aa-5c0e-44d7-8655-47e73df32291" />)

One variable. Completely different infrastructure. That is the power 
of conditionals.

---

## count vs for_each - My Honest Take

After today I have a very clear opinion. Use `count` only when you 
are creating truly identical resources and the number will never 
change. The moment your list is driven by a variable that anyone 
might modify, use `for_each`. No exceptions.

The `count` ordering problem does not announce itself. It waits until 
someone removes an item from the middle of a list and then silently 
destroys and recreates resources that were never meant to change. 
In production that means unexpected downtime.

`for_each` is not just the safer choice. It is the professional choice.

---

## What Day 10 Taught Me

Terraform is not just a tool for declaring infrastructure. With loops, 
expressions and conditionals it becomes a language for describing 
infrastructure dynamically. The same configuration that creates three 
users today can create thirty tomorrow without changing a single 
resource block.

That scalability is what separates configurations that work from 
configurations that last.

Day 11, let's go.
