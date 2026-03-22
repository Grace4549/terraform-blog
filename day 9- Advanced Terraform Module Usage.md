# Advanced Terraform Module Usage: Versioning, Gotchas, and Reuse Across Environments

Day 9 of the 30-Day Terraform Challenge and today was the day everything 
about modules got real.

Yesterday I built my first module. Today I learned how to version it, 
share it, and deploy different versions across environments like a 
professional infrastructure team would. I also learned the three gotchas 
that catch engineers off guard in production. Spoiler; one of them can 
cause downtime without a single error message.

---

## The Three Gotchas Nobody Warns You About

### Gotcha 1: File Paths Inside Modules

This one is subtle. If your module references a file using a relative 
path, that path resolves relative to where Terraform is run, not where 
the module lives. So when you call the module from a different directory, 
the file suddenly cannot be found.

The fix is always use `path.module`:
```hcl
user_data = templatefile("${path.module}/user-data.sh", {
  server_port = var.server_port
})
```

`path.module` always points to the module's own directory, no matter 
where Terraform is run from. One line. Saves hours of debugging.

### Gotcha 2: Inline Blocks vs Separate Resources

Some AWS resources support two ways of configuring the same thing: inline blocks inside the resource, or separate standalone resources. 
Mixing both in a module causes conflicts that are hard to trace.

The rule is simple. Pick one approach and never mix them. Separate 
resources are the better choice for modules because callers can add 
rules without modifying the module itself.

### Gotcha 3: Module Output Dependencies

If you use `depends_on` on an entire module, Terraform evaluates 
everything inside that module as a dependency, not just the specific 
resource you care about. This causes unnecessary resource recreation 
on every apply.

The fix is to reference a specific module output instead of depending 
on the whole module. Granular outputs are not just nice to have, they are how you keep your plans predictable.

---

## Pushing the Module to GitHub

With the gotchas understood, the next step was pushing the module to 
its own GitHub repository so it could be versioned and shared.

<img width="449" height="134" alt="image" src="https://github.com/user-attachments/assets/0662f0c1-4b5a-4c4b-9383-899a52f5741a" />


Once the code was on GitHub, I tagged the first release:
```powershell
git tag -a "v0.0.1" -m "First release of webserver-cluster module"
git push origin v0.0.1
```

Then I made a meaningful change by adding an `environment` input variable 
that tags every resource with its environment name. That became v0.0.2:
```powershell
git tag -a "v0.0.2" -m "Add environment input variable"
git push origin v0.0.2
```

<img width="341" height="39" alt="image" src="https://github.com/user-attachments/assets/df353256-8fef-45f7-8616-893afc294552" />


<img width="806" height="362" alt="image" src="https://github.com/user-attachments/assets/c4c6b915-1cb3-428e-8a81-92a30c1bec36" />


---

## Deploying Different Versions Across Environments

This is where it got interesting. Instead of pointing both environments 
at a local path, I updated the calling configurations to reference 
specific versions from GitHub:
```hcl
# dev — testing the latest version
module "webserver_cluster" {
  source        = "github.com/Grace4549/terraform-aws-webserver-cluster?ref=v0.0.2"
  cluster_name  = "webservers-dev"
  instance_type = "t3.micro"
  min_size      = 1
  max_size      = 2
  environment   = "dev"
}
```
```hcl
# production — pinned to the stable version
module "webserver_cluster" {
  source        = "github.com/Grace4549/terraform-aws-webserver-cluster?ref=v0.0.1"
  cluster_name  = "webservers-production"
  instance_type = "t3.micro"
  min_size      = 1
  max_size      = 2
}
```

When I ran `terraform init` in dev, Terraform pulled v0.0.2 directly 
from GitHub. When I ran it in production, it pulled v0.0.1. Same 
configuration file pattern, completely different module versions.

Both environments deployed successfully and produced their own ALB 
DNS names:

<img width="332" height="62" alt="image" src="https://github.com/user-attachments/assets/12cedce5-edef-4f61-8577-8070434c348c" />


<img width="686" height="107" alt="image" src="https://github.com/user-attachments/assets/9dc535f1-c38b-45cc-94ee-f6f74d33b45b" />


---

## Why Version Pinning Matters

Here is a scenario that happens in real teams. Two engineers are 
working on the same infrastructure. Engineer A runs `terraform apply` 
on Monday. The module source gets updated on Tuesday. Engineer B runs 
`terraform apply` on Wednesday. They both think they deployed the same 
thing, but they didn't.

Without version pins, your infrastructure becomes unpredictable. With 
version pins, every apply is deterministic. Dev tests new versions first. 
Production stays on the validated version until the team is confident. 
That is not just good practice, it is how you sleep at night knowing 
production is stable.

---

## The Moment That Proved the Point

When I tried to apply production with the `environment` argument, 
Terraform threw an error. Production was on v0.0.1, which did not have 
that variable yet, as it was added in v0.0.2. I had to remove the argument 
from the production configuration.

That error was not a failure. It was the versioning system working 
exactly as designed. Production was protected from a change it was 
not ready for.

---

## What Day 9 Taught Me

Modules without versions are just shared code waiting to cause problems. 
Modules with versions are infrastructure contracts; a promise that 
anyone calling this module at this version gets exactly this behaviour, 
every time, forever.

That is the difference between infrastructure that works and 
infrastructure that scales.

Day 10, let's go.
