# Quick Reference Guide

## Essential Commands

### Initial Setup
```bash
# Setup AWS resources
bash setup.sh

# Initialize Terraform
cd terraform && terraform init
```

### Dev Environment
```bash
# Create and select dev workspace
terraform workspace new dev
terraform workspace select dev

# Deploy
terraform plan
terraform apply

# Get outputs
terraform output
terraform output application_url

# Destroy
terraform destroy
```

### Prod Environment
```bash
# Create and select prod workspace
terraform workspace new prod
terraform workspace select prod

# Deploy
terraform plan
terraform apply

# Destroy
terraform destroy
```

### Monitoring
```bash
# View CloudWatch logs
aws logs tail /aws/ec2/dev/application --follow
aws logs tail /aws/ec2/prod/application --follow

# Check instance status
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev"

# List S3 artifacts
aws s3 ls s3://dev-app-artifacts-$(aws sts get-caller-identity --query Account --output text)/
```

### Testing Application
```bash
# Get application URL
APP_URL=$(cd terraform && terraform output -raw application_url)

# Test endpoints
curl $APP_URL/
curl $APP_URL/health
```

### Terraform Operations
```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state
terraform show

# List resources
terraform state list

# View specific resource
terraform state show aws_instance.web

# Refresh state
terraform refresh

# Import existing resource
terraform import aws_instance.web i-1234567890abcdef0
```

### Workspace Management
```bash
# List workspaces
terraform workspace list

# Show current workspace
terraform workspace show

# Switch workspace
terraform workspace select dev

# Delete workspace
terraform workspace delete dev
```

### State Management
```bash
# Pull remote state
terraform state pull > terraform.tfstate.backup

# Push state (dangerous!)
terraform state push terraform.tfstate

# Remove resource from state
terraform state rm aws_instance.web

# Move resource in state
terraform state mv aws_instance.web aws_instance.web_server
```

### Troubleshooting
```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform apply

# Force unlock state
terraform force-unlock <lock-id>

# Taint resource (force recreation)
terraform taint aws_instance.web

# Untaint resource
terraform untaint aws_instance.web

# Replace specific resource
terraform apply -replace=aws_instance.web
```

### Git Workflow
```bash
# Initial setup
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin <repo-url>
git push -u origin main

# Create develop branch
git checkout -b develop
git push -u origin develop

# Feature workflow
git checkout -b feature/new-feature
# Make changes
git add .
git commit -m "Add new feature"
git push -u origin feature/new-feature
# Create PR to develop

# Deploy to dev
git checkout develop
git merge feature/new-feature
git push

# Deploy to prod
git checkout main
git merge develop
git push
```

### AWS CLI Helpers
```bash
# Get account ID
aws sts get-caller-identity --query Account --output text

# List EC2 instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' --output table

# List S3 buckets
aws s3 ls

# List CloudWatch log groups
aws logs describe-log-groups --query 'logGroups[*].logGroupName' --output table

# Get instance console output
aws ec2 get-console-output --instance-id <instance-id> --output text
```

### Cost Monitoring
```bash
# Get current month costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost

# List resources by tag
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Environment,Values=dev
```

## File Locations

- Terraform configs: `terraform/`
- Application code: `app/`
- CI/CD pipeline: `.github/workflows/terraform.yml`
- Documentation: `README.md`, `DEPLOYMENT.md`

## Important URLs

- AWS Console: https://console.aws.amazon.com
- Terraform Registry: https://registry.terraform.io
- GitHub Actions: https://github.com/<user>/<repo>/actions

## Environment Variables

```bash
# AWS credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Terraform
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log
```

## Default Values

- **AWS Region**: us-east-1
- **Dev VPC CIDR**: 10.0.0.0/16
- **Prod VPC CIDR**: 10.1.0.0/16
- **Dev Instance**: t2.micro
- **Prod Instance**: t3.small
- **App Port**: 5000
- **State Bucket**: terraform-state-prod-infra-2024
- **Lock Table**: terraform-state-lock

## Resource Naming Convention

- VPC: `{env}-vpc`
- Subnet: `{env}-public-subnet`
- Security Group: `{env}-web-sg`
- EC2 Instance: `{env}-web-server`
- IAM Role: `{env}-ec2-role`
- S3 Bucket: `{env}-app-artifacts-{account-id}`
- Log Group: `/aws/ec2/{env}/application`
