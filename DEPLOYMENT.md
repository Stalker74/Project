# Deployment Guide

## Prerequisites Checklist

- [ ] AWS Account with admin access
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.0 installed
- [ ] Git installed
- [ ] GitHub account (for CI/CD)

## Step-by-Step Deployment

### 1. Initial AWS Setup (One-Time)

Create the S3 bucket and DynamoDB table for Terraform state:

```bash
# Option A: Use the setup script
bash setup.sh

# Option B: Manual creation
aws s3api create-bucket --bucket terraform-state-prod-infra-2024 --region us-east-1
aws dynamodb create-table --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region us-east-1
```

### 2. Local Deployment

#### Deploy Dev Environment

```bash
cd terraform
terraform init
terraform workspace new dev
terraform workspace select dev
terraform plan
terraform apply -auto-approve
```

#### Get Application URL

```bash
terraform output application_url
```

#### Test Application

```bash
# Replace with your actual IP
curl http://YOUR_INSTANCE_IP:5000/
curl http://YOUR_INSTANCE_IP:5000/health
```

#### View Logs

```bash
# Get log group name
terraform output cloudwatch_log_group

# Tail logs
aws logs tail /aws/ec2/dev/application --follow
```

### 3. Deploy Production Environment

```bash
terraform workspace new prod
terraform workspace select prod
terraform plan
# Review the plan carefully
terraform apply
```

### 4. CI/CD Setup (GitHub Actions)

#### Configure GitHub Repository

1. Push code to GitHub:
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin <your-repo-url>
git push -u origin main
```

2. Create develop branch:
```bash
git checkout -b develop
git push -u origin develop
```

#### Configure GitHub Secrets

1. Go to repository Settings → Secrets and variables → Actions
2. Add secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

#### Configure GitHub Environments

1. Go to Settings → Environments
2. Create three environments:
   - `dev`: No protection rules
   - `prod-plan`: No protection rules
   - `prod`: Enable "Required reviewers" and add yourself

#### Test CI/CD Pipeline

```bash
# Trigger dev deployment
git checkout develop
echo "# Test change" >> README.md
git add .
git commit -m "Test dev deployment"
git push

# Trigger prod deployment (requires approval)
git checkout main
git merge develop
git push
```

### 5. Monitoring and Maintenance

#### Check Infrastructure Status

```bash
cd terraform
terraform workspace select dev
terraform show
```

#### View CloudWatch Logs

```bash
# Via CLI
aws logs tail /aws/ec2/dev/application --follow

# Via Console
# Navigate to CloudWatch → Log groups → /aws/ec2/dev/application
```

#### Check S3 Artifacts

```bash
aws s3 ls s3://dev-app-artifacts-<account-id>/
```

#### SSH to Instance (if needed)

```bash
# Get instance IP
terraform output instance_public_ip

# SSH (requires key pair - add to terraform if needed)
ssh -i your-key.pem ec2-user@<instance-ip>

# Check application status
sudo systemctl status webapp
sudo journalctl -u webapp -f
```

### 6. Making Changes

#### Update Infrastructure

```bash
# Edit terraform files
vim terraform/main.tf

# Plan changes
terraform plan

# Apply changes
terraform apply
```

#### Update Application

```bash
# Edit app code
vim app/app.py

# Redeploy (forces new user-data execution)
terraform apply -replace=aws_instance.web
```

### 7. Cleanup

#### Destroy Dev Environment

```bash
terraform workspace select dev
terraform destroy
```

#### Destroy Prod Environment

```bash
terraform workspace select prod
terraform destroy
```

#### Remove State Storage (Optional)

```bash
aws s3 rb s3://terraform-state-prod-infra-2024 --force
aws dynamodb delete-table --table-name terraform-state-lock
```

## Common Issues and Solutions

### Issue: State Lock Error

```bash
# List locks
aws dynamodb scan --table-name terraform-state-lock

# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Issue: EC2 Instance Not Responding

```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids <instance-id>

# View system logs
aws ec2 get-console-output --instance-id <instance-id>

# Check security group
aws ec2 describe-security-groups --group-ids <sg-id>
```

### Issue: Application Not Logging

```bash
# SSH to instance
ssh ec2-user@<instance-ip>

# Check CloudWatch agent
sudo systemctl status amazon-cloudwatch-agent
sudo cat /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Check application logs locally
sudo tail -f /var/log/app.log
```

### Issue: Terraform Backend Initialization Failed

```bash
# Verify S3 bucket exists
aws s3 ls s3://terraform-state-prod-infra-2024

# Verify DynamoDB table exists
aws dynamodb describe-table --table-name terraform-state-lock

# Re-run setup if needed
bash setup.sh
```

## Best Practices

1. **Always review plans** before applying
2. **Use workspaces** for environment separation
3. **Enable MFA** for production approvals
4. **Regular backups** of Terraform state
5. **Tag all resources** appropriately
6. **Monitor costs** using AWS Cost Explorer
7. **Rotate credentials** regularly
8. **Use least privilege** IAM policies
9. **Enable CloudTrail** for audit logging
10. **Document changes** in commit messages

## Security Checklist

- [ ] AWS credentials stored securely (not in code)
- [ ] S3 buckets encrypted
- [ ] EBS volumes encrypted
- [ ] Security groups follow least privilege
- [ ] IAM roles use minimal permissions
- [ ] CloudWatch logging enabled
- [ ] Terraform state encrypted
- [ ] State locking enabled
- [ ] No public access to S3 buckets
- [ ] SSH access restricted to known IPs

## Cost Optimization

- Use t2.micro for dev (free tier eligible)
- Enable S3 lifecycle policies for old logs
- Use CloudWatch log retention policies
- Stop dev instances when not in use
- Monitor with AWS Cost Explorer
- Set up billing alerts

## Next Steps

1. Add RDS database for persistent storage
2. Implement Auto Scaling Groups
3. Add Application Load Balancer
4. Set up Route53 for DNS
5. Implement SSL/TLS certificates
6. Add WAF for security
7. Implement backup strategies
8. Add monitoring dashboards
9. Set up alerting with SNS
10. Implement disaster recovery plan
