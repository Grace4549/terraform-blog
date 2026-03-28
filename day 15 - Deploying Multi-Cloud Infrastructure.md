# Deploying Multi-Cloud Infrastructure with Terraform Modules

Day 15 of the 30-Day Terraform Challenge and today was the most 
technically dense day yet. Three completely different providers. 
Three completely different deployment targets. One tool managing 
all of it.

By the end of today I had S3 buckets running in two AWS regions, 
an nginx container running locally in Docker, and two nginx pods 
running on a Kubernetes cluster on AWS; all provisioned by 
Terraform. Let me walk you through how.

---

## Part 1: Modules That Work Across Regions

Yesterday I used provider aliases to deploy resources in multiple 
regions from a root configuration. Today I learned how to pass 
those providers into a module; which is a completely different 
challenge.

The problem with putting provider blocks inside a module is that 
the provider becomes fixed. The module can only ever deploy to 
one specific region. By removing provider blocks from the module 
and using `configuration_aliases` instead, the module becomes 
genuinely reusable and the caller decides where things go.

The module declares what it needs:
```hcl
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.primary, aws.replica]
    }
  }
}
```

The caller provides what the module needs:
```hcl
module "multi_region_app" {
  source   = "../modules/multi-region-app"
  app_name = "grace-terraform"

  providers = {
    aws.primary = aws.primary
    aws.replica = aws.replica
  }
}
```

One module. Two regions. Zero hardcoding.


<img width="538" height="139" alt="image" src="https://github.com/user-attachments/assets/961af6d1-af53-4b30-a196-53b16b889e51" />



---

## Part 2: Managing Docker Containers with Terraform

Before jumping into EKS I deployed nginx locally using the Docker 
provider. This is one of my favourite things I have learned in 
this challenge. You can manage containers the same way you manage 
cloud infrastructure. Same workflow, same commands, completely 
different target.
```hcl
resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "terraform-nginx"

  ports {
    internal = 80
    external = 8080
  }
}
```

One `terraform apply` later:

<img width="911" height="98" alt="image" src="https://github.com/user-attachments/assets/21f72492-c804-4678-90f0-5f34b3fbc652" />

<img width="641" height="259" alt="image" src="https://github.com/user-attachments/assets/8ed3bb28-c456-4bd6-b854-fcfb920977d2" />


Seeing nginx serve a response from a container that Terraform 
created in seconds is genuinely satisfying. Then `terraform destroy` 
and it is gone. Clean. Simple. Repeatable.

---

## Part 3: A Full EKS Cluster - The Big One

This was the most complex deployment of the entire challenge so far. 
A VPC, a managed Kubernetes cluster, worker nodes, and an nginx 
deployment. All from Terraform code.

The EKS module handles the heavy lifting:
```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "terraform-challenge-cluster"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["t3.small"]
    }
  }
}
```

The Kubernetes provider connects to the cluster using outputs 
from the EKS module. The `exec` block runs `aws eks get-token` 
at apply time to get a fresh authentication token — no hardcoded 
credentials anywhere:
```hcl
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}
```

Then the nginx deployment onto the cluster:
```hcl
resource "kubernetes_deployment" "nginx" {
  metadata {
    name   = "nginx-deployment"
    labels = { app = "nginx" }
  }

  spec {
    replicas = 2

    selector {
      match_labels = { app = "nginx" }
    }

    template {
      metadata {
        labels = { app = "nginx" }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"
          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [module.eks]
}
```

The cluster took about 15 minutes to provision. Then:
<img width="629" height="143" alt="image" src="https://github.com/user-attachments/assets/00f5a076-cdd0-4724-93c9-67f1557ade45" />


Two pods. Both running. Zero manual console clicks.

---

## The Bit Nobody Warned Me About

Getting the Kubernetes provider to authenticate to the EKS cluster 
was not straightforward. The first few attempts failed with 
Unauthorized errors because my IAM user did not have the right 
permissions to get a token from EKS.

The fix involved creating an EKS access entry for the IAM user, 
associating the cluster admin policy, and attaching the 
AmazonEKSClusterPolicy directly to the user. Once that was done 
`kubectl get nodes` returned a healthy node and everything worked.

The lesson - EKS authentication has multiple layers. Your IAM 
user needs permissions both to call the EKS API and to be 
recognised as a valid user inside the cluster itself.

---

## A Word on Cost

EKS is not free. The control plane alone costs $0.10 per hour. 
Add EC2 worker nodes and a NAT gateway and you are looking at 
roughly $5 to $10 for 24 hours. I destroyed the cluster 
immediately after confirming the deployment worked.

If you are doing this challenge, destroy your EKS cluster the 
moment you have your screenshots. Do not leave it running overnight.

---

## What Day 15 Taught Me

Terraform is not just an AWS tool. It is a universal infrastructure 
API. The same workflow that creates an S3 bucket can create a Docker 
container or a Kubernetes deployment. The provider system is what 
makes this possible. And today I used three different providers in 
one day.

The multi-provider module pattern is something I will use in every 
serious project going forward. Write the module once. Let the caller 
decide where it deploys. That is clean infrastructure engineering.

Day 16, let's go.
