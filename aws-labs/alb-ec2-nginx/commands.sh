#!/usr/bin/env bash
# The lab was done in the AWS Console. These are the AWS CLI equivalents.
# Replace the placeholders before running.
set -euo pipefail

VPC_ID="<vpc-id>"
SUBNETS="<subnet-id-az-a> <subnet-id-az-b>"   # at least two AZs
INSTANCE_ID="<instance-id>"                     # nautilus-ec2
INSTANCE_SG="<instance-default-sg-id>"

# 1. ALB security group: HTTP 80 from anywhere
ALB_SG=$(aws ec2 create-security-group --group-name nautilus-sg \
  --description "ALB public HTTP" --vpc-id "$VPC_ID" --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id "$ALB_SG" \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

# 2. Target group with the instance registered
TG_ARN=$(aws elbv2 create-target-group --name nautilus-tg --protocol HTTP --port 80 \
  --vpc-id "$VPC_ID" --target-type instance --health-check-path / \
  --query "TargetGroups[0].TargetGroupArn" --output text)
aws elbv2 register-targets --target-group-arn "$TG_ARN" --targets Id="$INSTANCE_ID",Port=80

# 3. Internet-facing ALB and HTTP:80 listener
# shellcheck disable=SC2086
ALB_ARN=$(aws elbv2 create-load-balancer --name nautilus-alb --type application \
  --scheme internet-facing --subnets $SUBNETS --security-groups "$ALB_SG" \
  --query "LoadBalancers[0].LoadBalancerArn" --output text)
aws elbv2 create-listener --load-balancer-arn "$ALB_ARN" --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn="$TG_ARN"

# 4. Instance SG: allow HTTP only from the ALB's security group
aws ec2 authorize-security-group-ingress --group-id "$INSTANCE_SG" \
  --protocol tcp --port 80 --source-group "$ALB_SG"

# 5. Verify
aws elbv2 wait load-balancer-available --load-balancer-arns "$ALB_ARN"
aws elbv2 describe-target-health --target-group-arn "$TG_ARN" \
  --query "TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]" --output table
DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" \
  --query "LoadBalancers[0].DNSName" --output text)
curl -s "http://$DNS" | head -20
