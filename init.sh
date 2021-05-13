#!/usr/bin/env bash

bucket="terraform-eks-poc-infrastructure"
region="eu-central-1"

aws s3 mb s3://$bucket --region $region

aws s3api put-public-access-block \
    --bucket $bucket \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

aws s3api put-bucket-encryption \
    --bucket $bucket \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

aws s3api put-bucket-versioning --bucket $bucket --versioning-configuration Status=Enabled

aws s3api put-bucket-policy --bucket $bucket --policy file://bucket-policy.json

terraform init
