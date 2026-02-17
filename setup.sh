#!/bin/bash
# Setup script for initial AWS resources (S3 bucket and DynamoDB table)

set -e

BUCKET_NAME="terraform-state-prod-infra-2024"
TABLE_NAME="terraform-state-lock"
REGION="us-east-1"

echo "🚀 Setting up AWS resources for Terraform remote state..."

# Create S3 bucket
echo "📦 Creating S3 bucket: $BUCKET_NAME"
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $REGION 2>/dev/null || echo "Bucket already exists"

# Enable versioning
echo "🔄 Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Enable encryption
echo "🔒 Enabling encryption..."
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Block public access
echo "🛡️  Blocking public access..."
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create DynamoDB table
echo "🗄️  Creating DynamoDB table: $TABLE_NAME"
aws dynamodb create-table \
  --table-name $TABLE_NAME \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION 2>/dev/null || echo "Table already exists"

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. cd terraform"
echo "2. terraform init"
echo "3. terraform workspace new dev"
echo "4. terraform plan"
echo "5. terraform apply"
