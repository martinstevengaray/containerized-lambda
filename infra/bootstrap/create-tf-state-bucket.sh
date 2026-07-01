#!/usr/bin/env bash
# Run once, before `terraform init`, to create the S3 bucket that holds Terraform state.
# Idempotent: create-bucket errors if the bucket already exists
set -euo pipefail

# Grab your account id for a unique bucket name
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="tfstate-${ACCOUNT_ID}"
REGION="us-west-2"

# Create the bucket
aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"

# Versioning: allows recovery if state gets corrupted or a bad apply happens
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

# Default encryption at rest (SSE-S3)
aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'

# Block all public access — state can contain secrets, this must never be public
aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
