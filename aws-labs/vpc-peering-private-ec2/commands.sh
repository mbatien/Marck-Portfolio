#!/usr/bin/env bash
# The lab was done in the AWS Console. These are the AWS CLI equivalents.
# Replace the placeholders before running.
set -euo pipefail

DEFAULT_VPC_ID="<default-vpc-id>"            # 172.31.0.0/16
PRIVATE_VPC_ID="<xfusion-private-vpc-id>"    # 10.1.0.0/16
DEFAULT_RTB_ID="<default-vpc-route-table-id>"
PRIVATE_RTB_ID="<private-vpc-route-table-id>"
PRIVATE_SG_ID="<private-instance-sg-id>"

# 1. Create and accept the peering connection
PCX_ID=$(aws ec2 create-vpc-peering-connection \
  --vpc-id "$DEFAULT_VPC_ID" --peer-vpc-id "$PRIVATE_VPC_ID" \
  --tag-specifications 'ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=xfusion-vpc-peering}]' \
  --query VpcPeeringConnection.VpcPeeringConnectionId --output text)
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id "$PCX_ID"

# 2. Routes on BOTH sides
aws ec2 create-route --route-table-id "$DEFAULT_RTB_ID" \
  --destination-cidr-block 10.1.0.0/16 --vpc-peering-connection-id "$PCX_ID"
aws ec2 create-route --route-table-id "$PRIVATE_RTB_ID" \
  --destination-cidr-block 172.31.0.0/16 --vpc-peering-connection-id "$PCX_ID"

# 3. Allow ICMP into the private instance from the default VPC
aws ec2 authorize-security-group-ingress --group-id "$PRIVATE_SG_ID" \
  --ip-permissions 'IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=172.31.0.0/16}]'

# 4. Verify
aws ec2 describe-vpc-peering-connections --vpc-peering-connection-ids "$PCX_ID" \
  --query "VpcPeeringConnections[0].Status.Code" --output text   # active

# 5. From the aws-client host (after adding its public key to the public
#    instance's ~ec2-user/.ssh/authorized_keys, e.g. via EC2 Instance Connect):
#    cat /root/.ssh/id_rsa.pub
#    ssh ec2-user@<public-instance-ip>
#    ping -c 4 <private-instance-private-ip>
