# Marck's DevOps Portfolio

Two connected projects: an AWS platform built with Terraform (Project 1), and an app deployed onto it by a CI/CD pipeline (Project 2).

```
Marck-Portfolio/
├── terraform-platform/   Project 1: VPC, ALB, ECS Fargate, RDS, ECR (Terraform)
├── orders-api/           Project 2: FastAPI app, Dockerfile, CodeBuild pipeline
├── aws-labs/             Hands-on AWS lab tasks (CLI, Console, Terraform)
├── .pre-commit-config.yaml  (work in progress, see terraform-platform/README.md)
└── .tflint.hcl
```

## 1. [AWS Terraform Platform](terraform-platform/)

Production-style AWS infrastructure built entirely with Terraform: a three-AZ VPC, an Application Load Balancer, an ECS Fargate service with auto scaling, PostgreSQL on RDS with Secrets Manager, and ECR, deployed to separate **dev** and **prod** environments with remote S3 state, native state locking, and TFLint linting.

![Architecture](terraform-platform/docs/architecture.png)

**Stack:** Terraform · AWS (VPC, ALB, ECS Fargate, RDS PostgreSQL, ECR, S3, CloudWatch, Secrets Manager) · TFLint

See the [project README](terraform-platform/README.md) for the architecture, design decisions, setup steps and lessons learned.

## 2. [Orders API with AWS CI/CD](orders-api/)

A Python (FastAPI) orders service on PostgreSQL, deployed by an AWS-native pipeline: GitHub → CodePipeline → CodeBuild (lint, tests against a real PostgreSQL, Docker build, push to ECR) → rolling ECS deploy with automatic rollback. It runs on the Project 1 platform. See the [project README](orders-api/README.md) for the pipeline setup and design choices.

**Stack:** AWS CodePipeline · CodeBuild · CodeConnections · ECR · ECS Fargate · Python · FastAPI · PostgreSQL · Docker

## [AWS Labs](aws-labs/)

Hands-on AWS tasks from the KodeKloud Engineer platform, each documented with the commands or Terraform code to reproduce it and a short write-up of the problem, the solution and what went wrong along the way.
