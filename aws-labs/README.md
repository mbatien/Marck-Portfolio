# AWS Labs

Hands-on AWS tasks completed on the KodeKloud Engineer platform (100 Days of Cloud and the AWS tasks in 100 Days of DevOps). Each lab folder holds the commands, code and a short write-up: what the task asked, how I solved it, and anything that broke along the way.

Lab environments are temporary, so every lab here is documented with the CLI commands or Terraform code needed to reproduce it in any AWS account.

## Labs

| Lab | Services | Tools | What it shows |
| --- | --- | --- | --- |
| [Application Load Balancer in front of EC2](alb-ec2-nginx/) | EC2, ALB, Target groups, Security groups | Console | Internet-facing ALB across multiple AZs; health-checked targets; security-group chaining so only the ALB reaches the instance |
| [CI/CD for a static website with CodePipeline](codepipeline-s3-static-website/) | S3, CodePipeline, CodeBuild, IAM, EventBridge | Console | Automated deploy on every source change; S3 static hosting; least-privilege CodeBuild role |

## Layout

```
aws-labs/
├── README.md                  this index
├── templates/LAB_TEMPLATE.md  outline every lab write-up follows
├── scripts/new-lab.sh         creates a new lab folder from the template
└── <lab-name>/
    ├── README.md              goal, steps, verification, troubleshooting
    ├── commands.sh            AWS CLI commands used
    └── *.tf / *.json / *.yaml code and policies (when the lab has them)
```

## Adding a lab

```bash
./aws-labs/scripts/new-lab.sh rds-mysql-engine-upgrade
```

Then fill in the README, paste the commands into `commands.sh`, add any code, and commit.

Before committing, replace account IDs, lab usernames, passwords and access keys with placeholders like `<account-id>`.
