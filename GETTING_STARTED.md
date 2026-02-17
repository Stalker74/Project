# Getting Started

Welcome! This guide will help you deploy your production-style AWS infrastructure in minutes.

## 🎯 What You'll Build

- Complete AWS infrastructure (VPC, EC2, S3, IAM, CloudWatch)
- Flask web application with health monitoring
- CI/CD pipeline with GitHub Actions
- Multi-environment setup (dev/prod)
- Remote state management with S3 and DynamoDB

## ⚡ Quick Start (5 Minutes)

### Step 1: Prerequisites

Ensure you have:
- AWS account with admin access
- AWS CLI installed and configured
- Terraform >= 1.0 installed

```bash
# Verify installations
aws --version
terraform --version
```

### Step 2: Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region: us-east-1
# Enter default output format: json
```

### Step 3: Setup Remote State Storage

```bash
# Run the setup script
bash setup.sh
```

This creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking

### Step 4: Deploy Dev Environment

```bash
cd terraform
terraform init
terraform workspace new dev
terraform workspace select dev
terraform plan
terraform apply
```

Type `yes` when prompted.

### Step 5: Access Your Application

```bash
# Get the application URL
terraform output application_url

# Test it
curl $(terraform output -raw application_url)/health
```

You should see: `{"status":"ok"}`

## 🎉 Success!

Your infrastructure is now running! Here's what was created:

- ✅ VPC with public subnet
- ✅ EC2 instance running Flask app
- ✅ S3 bucket for artifacts
- ✅ CloudWatch logs
- ✅ IAM roles and security groups

## 📊 View Your Infrastructure

### AWS Console
1. Go to https://console.aws.amazon.com
2. Navigate to EC2 → Instances
3. Find your instance tagged with Environment=dev

### CloudWatch Logs
```bash
# View application logs
aws logs tail /aws/ec2/dev/application --follow
```

### Test Endpoints
```bash
APP_URL=$(cd terraform && terraform output -raw application_url)

# Health check
curl $APP_URL/health

# Main endpoint
curl $APP_URL/
```

## 🚀 Next Steps

### 1. Deploy to Production

```bash
terraform workspace new prod
terraform workspace select prod
terraform plan
terraform apply
```

### 2. Setup CI/CD Pipeline

1. Create GitHub repository
2. Push your code:
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin <your-repo-url>
git push -u origin main
```

3. Configure GitHub Secrets:
   - Go to Settings → Secrets → Actions
   - Add `AWS_ACCESS_KEY_ID`
   - Add `AWS_SECRET_ACCESS_KEY`

4. Configure GitHub Environments:
   - Go to Settings → Environments
   - Create `dev`, `prod-plan`, and `prod` environments
   - For `prod`: Enable "Required reviewers"

5. Create develop branch:
```bash
git checkout -b develop
git push -u origin develop
```

Now every push to `develop` deploys to dev, and every push to `main` requires approval for prod!

### 3. Monitor Your Application

```bash
# Watch logs in real-time
aws logs tail /aws/ec2/dev/application --follow

# Check instance status
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev"

# View S3 artifacts
aws s3 ls s3://$(cd terraform && terraform output -raw s3_bucket_name)/
```

## 📚 Learn More

- **[README.md](README.md)** - Complete documentation
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Detailed deployment guide
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Command cheat sheet
- **[TESTING.md](TESTING.md)** - Testing and validation
- **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)** - Architecture details

## 🛠️ Common Commands

```bash
# View all outputs
terraform output

# View specific output
terraform output application_url

# List all resources
terraform state list

# Show resource details
terraform state show aws_instance.web

# Destroy infrastructure
terraform destroy
```

## 🆘 Need Help?

### Application Not Accessible?
```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids $(terraform output -raw instance_id)

# View console output
aws ec2 get-console-output --instance-id $(terraform output -raw instance_id)
```

### Logs Not Showing?
```bash
# Check CloudWatch agent on instance (requires SSH)
ssh ec2-user@$(terraform output -raw instance_public_ip)
sudo systemctl status amazon-cloudwatch-agent
```

### Terraform Errors?
```bash
# Enable debug mode
export TF_LOG=DEBUG
terraform apply
```

## 🧹 Cleanup

When you're done experimenting:

```bash
# Destroy dev environment
terraform workspace select dev
terraform destroy

# Destroy prod environment
terraform workspace select prod
terraform destroy

# Optional: Remove state storage
aws s3 rb s3://terraform-state-prod-infra-2024 --force
aws dynamodb delete-table --table-name terraform-state-lock
```

## 💡 Tips

1. **Always review plans** before applying
2. **Use workspaces** to keep environments separate
3. **Check CloudWatch logs** for troubleshooting
4. **Tag resources** for cost tracking
5. **Enable MFA** for production deployments

## 🎓 What You've Learned

- ✅ Infrastructure as Code with Terraform
- ✅ AWS networking (VPC, subnets, security groups)
- ✅ EC2 instance management
- ✅ IAM roles and policies
- ✅ CloudWatch logging
- ✅ S3 storage
- ✅ Remote state management
- ✅ Multi-environment deployments
- ✅ CI/CD with GitHub Actions

## 🌟 Extend This Project

Ideas for enhancement:
- Add RDS database
- Implement Auto Scaling
- Add Application Load Balancer
- Configure SSL/TLS certificates
- Add Route53 DNS
- Implement blue-green deployment
- Add monitoring dashboards
- Set up alerting with SNS

## 📞 Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Documentation](https://docs.aws.amazon.com)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Flask Documentation](https://flask.palletsprojects.com)

---

**Ready to build production infrastructure? Let's go! 🚀**

Start with: `bash setup.sh`
