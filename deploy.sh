#!/bin/bash
set -e

read -p "Enter your S3 bucket name: " S3_BUCKET
read -p "Enter your AWS CLI profile name: " AWS_PROFILE
read -p "Enter your AWS region (e.g., ap-southeast-1): " REGION

echo ""
echo "==== Your inputs ===="
echo "S3_BUCKET   = $S3_BUCKET"
echo "AWS_PROFILE = $AWS_PROFILE"
echo "REGION      = $REGION"
echo ""

if aws s3api head-bucket --bucket $S3_BUCKET --profile $AWS_PROFILE 2>/dev/null; then
  echo "S3 bucket $S3_BUCKET already exists."
else
  echo "Creating S3 bucket $S3_BUCKET..."
  if [ "$REGION" == "us-east-1" ]; then
    aws s3api create-bucket --bucket $S3_BUCKET --region $REGION --object-ownership BucketOwnerPreferred --profile $AWS_PROFILE 
  else
    aws s3api create-bucket --bucket $S3_BUCKET \
      --region $REGION \
      --create-bucket-configuration LocationConstraint=$REGION \
      --object-ownership BucketOwnerPreferred \
      --profile $AWS_PROFILE
  fi
  echo "Waiting for S3 bucket to become available..."
  until aws s3api head-bucket --bucket $S3_BUCKET --profile $AWS_PROFILE 2>/dev/null; do
    sleep 2
  done
  echo "S3 bucket $S3_BUCKET is now ready."
fi

echo "Uploading all templates to S3 bucket $S3_BUCKET."
aws s3 cp ./vpc/vpc.yaml s3://$S3_BUCKET --profile $AWS_PROFILE
aws s3 cp ./nat/nat.yaml s3://$S3_BUCKET --profile $AWS_PROFILE
aws s3 cp ./route_table/route_table.yaml s3://$S3_BUCKET --profile $AWS_PROFILE
aws s3 cp ./security_group/security_group.yaml s3://$S3_BUCKET --profile $AWS_PROFILE
aws s3 cp ./ec2/ec2.yaml s3://$S3_BUCKET --profile $AWS_PROFILE
echo "All templates uploaded to S3 bucket $S3_BUCKET."