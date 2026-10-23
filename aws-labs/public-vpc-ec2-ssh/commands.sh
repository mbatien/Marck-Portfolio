#!/usr/bin/env bash
# The lab was done in the AWS Console. These are the AWS CLI equivalents.
# Replace the placeholders before running.
set -euo pipefail

REGION="us-east-1"
AMI_ID="<amazon-linux-2023-ami-id>"
KEY_NAME="<key-pair-name>"

# 1. VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/20 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=devops-pub-vpc}]' \
  --query Vpc.VpcId --output text)

# 2. Public subnet with auto-assigned public IPs
SUBNET_ID=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.0.0/20 \
  --availability-zone "${REGION}a" \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=devops-pub-subnet}]' \
  --query Subnet.SubnetId --output text)
aws ec2 modify-subnet-attribute --subnet-id "$SUBNET_ID" --map-public-ip-on-launch

# 3. Internet Gateway, attached to the VPC
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=devops-igw}]' \
  --query InternetGateway.InternetGatewayId --output text)
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"

# 4. Default route to the IGW on the VPC's main route table
RTB_ID=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.main,Values=true" \
  --query "RouteTables[0].RouteTableId" --output text)
aws ec2 create-route --route-table-id "$RTB_ID" \
  --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID"

# 5. Security group allowing SSH from anywhere (lab only)
SG_ID=$(aws ec2 create-security-group --group-name devops-pub-sg \
  --description "SSH from the internet" --vpc-id "$VPC_ID" --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" \
  --protocol tcp --port 22 --cidr 0.0.0.0/0

# 6. EC2 instance
INSTANCE_ID=$(aws ec2 run-instances --image-id "$AMI_ID" --instance-type t2.micro \
  --key-name "$KEY_NAME" --subnet-id "$SUBNET_ID" --security-group-ids "$SG_ID" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=devops-pub-ec2}]' \
  --query "Instances[0].InstanceId" --output text)

# 7. Verify
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
aws ec2 describe-route-tables --route-table-ids "$RTB_ID" \
  --query "RouteTables[0].Routes[*].[DestinationCidrBlock,GatewayId,State]" --output table
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
echo "ssh -i $KEY_NAME.pem ec2-user@$PUBLIC_IP"
