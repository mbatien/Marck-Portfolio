#!/usr/bin/env bash
# The lab was done in the AWS Console. These are the CLI equivalents of the
# bucket setup, plus the commands used to verify the result.
# Replace the placeholders before running.
set -euo pipefail

SOURCE_BUCKET="<source-bucket>"
DEPLOY_BUCKET="<deployment-bucket>"
REGION="us-east-1"

# --- Source bucket: inspect and enable versioning (required by CodePipeline) ---
aws s3 ls "s3://$SOURCE_BUCKET" --recursive
aws s3api put-bucket-versioning --bucket "$SOURCE_BUCKET" \
  --versioning-configuration Status=Enabled

# --- Website bucket ---
aws s3 mb "s3://$DEPLOY_BUCKET" --region "$REGION"

aws s3api put-public-access-block --bucket "$DEPLOY_BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

aws s3 website "s3://$DEPLOY_BUCKET/" --index-document index.html

sed "s/<deployment-bucket>/$DEPLOY_BUCKET/" bucket-policy.json > /tmp/bucket-policy.json
aws s3api put-bucket-policy --bucket "$DEPLOY_BUCKET" --policy file:///tmp/bucket-policy.json

# --- Pipeline and CodeBuild project were created in the console (see README) ---

# --- Verification ---
aws codepipeline get-pipeline-state --name webapp-pipeline \
  --query "stageStates[*].[stageName,latestExecution.status]" --output table
aws s3 ls "s3://$DEPLOY_BUCKET/"
curl -s "http://$DEPLOY_BUCKET.s3-website-$REGION.amazonaws.com" | head -20
