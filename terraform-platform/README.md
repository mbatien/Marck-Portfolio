# AWS Terraform Platform

> Production-style AWS infrastructure built entirely with Terraform: a three-AZ network, PostgreSQL on RDS, a container registry and an ECS Fargate service behind a load balancer, deployed to separate **dev** and **prod** environments, with linting and security scanning on every commit.

![Architecture](docs/architecture.png)

## Architecture

```
                    Internet
                       |
              Application Load Balancer          (public subnets, 3 AZs)
                       |
        ECS Fargate service (auto scaling)        (private app subnets, 3 AZs)
           |                         |
   RDS PostgreSQL               NAT gateway(s) -> internet (image pulls, APIs)
   (private data subnets,       S3 gateway endpoint -> S3/ECR layers
    Secrets Manager password)

   VPC Flow Logs -> CloudWatch Logs     Container logs -> CloudWatch Logs
```

| Layer | Module | Key choices |
| --- | --- | --- |
| Network | `modules/vpc` | /16 VPC, public /24 + app /20 + data /24 per AZ, NAT per AZ (one in dev), data tier has no internet route, S3 endpoint, Flow Logs, locked-down default SG |
| Registry | `modules/ecr` | Immutable tags, scan on push, lifecycle policy |
| Load balancer | `modules/alb` | IP target group for Fargate, optional HTTPS with ACM and HTTP→HTTPS redirect, drops invalid headers |
| Compute | `modules/ecs-service` | Fargate in private subnets, SG allows only the ALB, circuit breaker with rollback, CPU target tracking, ECS Exec, separate execution and task roles |
| Database | `modules/rds-postgres` | Private, encrypted gp3, password managed by Secrets Manager, Multi-AZ in prod, deletion protection in prod |

## Repository layout

```
bootstrap/                one-time, local state: the encrypted, versioned S3 state bucket
modules/                  reusable building blocks (each has its own variables/outputs)
  vpc/  ecr/  alb/  ecs-service/  rds-postgres/
envs/
  dev/                    cheap and disposable (1 NAT, 1 task, single-AZ DB)
  prod/                   resilient (NAT per AZ, 3 tasks, Multi-AZ DB, deletion protection)
.tflint.hcl               TFLint rules (Terraform + AWS rulesets)
.pre-commit-config.yaml   fmt, validate, TFLint, Checkov and gitleaks on every commit
```

## Prerequisites

Terraform >= 1.11, AWS CLI v2 with credentials for your account, TFLint, Checkov, pre-commit, and the AWS Session Manager plugin (only needed for ECS Exec into running containers).

## Getting started

```bash
# 0. Install the commit hooks once, then check everything locally
pre-commit install
pre-commit run --all-files          # fmt, validate, TFLint, Checkov, gitleaks
tflint --init

# 1. Bootstrap (once, local state)
cd bootstrap
# set state_bucket_name in terraform.tfvars
terraform init && terraform apply
terraform output state_bucket_name
cd ..

# 2. Point the remote-state configs at the bucket
#    bucket = "<state_bucket_name>" in envs/dev/backend.tf and envs/prod/backend.tf
#    owner  = "<you>" in envs/*/terraform.tfvars

# 3. Deploy dev
cd envs/dev
terraform init
terraform plan -out=tfplan          # read the plan before applying
terraform apply tfplan
terraform output app_url            # open it in a browser
cd ../..

# 4. Deploy prod the same way (only when your budget allows; destroy it afterwards)
cd envs/prod
terraform init && terraform plan -out=tfplan && terraform apply tfplan
```

## How changes are made

Every change follows the same workflow, run from my laptop:

1. **Commit:** pre-commit runs `terraform fmt`, `terraform validate`, TFLint, Checkov and gitleaks. A failing check blocks the commit.
2. **Plan:** `terraform plan -out=tfplan` in the environment's folder, and read every change.
3. **Apply the saved plan:** `terraform apply tfplan`, so what gets applied is exactly what was reviewed. Dev first, prod only after dev works.

## Design decisions

- **Separate state per environment** so a mistake in dev can never touch prod.
- **Modules + per-environment tfvars** instead of workspaces, because dev and prod deliberately differ.
- **Native S3 state locking** (`use_lockfile`) instead of a DynamoDB table.
- **Data subnets without an internet route**: the database can't reach or be reached from the internet.
- **RDS-managed master password** in Secrets Manager, injected into ECS at task start, so no secret is in code, state or the task definition.
- **Checks before every commit** (TFLint, Checkov, gitleaks) so mistakes, insecure settings and leaked secrets are caught before they reach AWS or GitHub.
- **Apply only a saved plan** so nothing changes between review and apply.
- _Add your own decisions as you make them._

## Known limitations (good interview material)

- Changes are applied from a laptop, so the review step depends on discipline. A CI pipeline that plans on pull requests and applies after approval would enforce it.
- Applies use my own AWS credentials; a pipeline would use a dedicated, short-lived role instead.

## Cost (approximate, us-east-1)

Dev runs at roughly a few dollars per day, mostly the NAT gateway, ALB and RDS. Destroy dev when you're not working. _Fill in your real numbers from Cost Explorer._

## Teardown

```bash
terraform -chdir=envs/prod destroy   # disable deletion protection on RDS/ALB first if enabled
terraform -chdir=envs/dev destroy
# bootstrap/ is kept until you're completely done (the state bucket has prevent_destroy)
```

## Challenges and lessons learned

_Write 2-3 real problems you hit, the cause and the fix._

## Next steps

- CI pipeline: checks and plan on pull requests, apply after approval
- HTTPS with a custom domain (ACM + Route 53)
- Split state into network / data / app layers
- Nightly drift detection (`terraform plan -detailed-exitcode`)
