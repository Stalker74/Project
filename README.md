# Production-Style AWS Infrastructure Automation

A complete production-ready infrastructure automation project demonstrating DevOps best practices using Terraform, AWS, and CI/CD pipelines.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                            │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │                VPC (10.0.0.0/16 or 10.1.0.0/16)    │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────┐     │    │
│  │  │         Public Subnet                     │     │    │
│  │  │                                           │     │    │
│  │  │  ┌─────────────────────────────────┐    │     │    │
│  │  │  │   EC2 Instance (Web Server)     │    │     │    │
│  │  │  │   - Flask Application           │    │     │    │
│  │  │  │   - CloudWatch Agent            │    │     │    │
│  │  │  │   - IAM Instance Profile        │    │     │    │
│  │  │  └─────────────────────────────────┘    │     │    │
│  │  │                                           │     │    │
│  │  └──────────────────────────────────────────┘     │    │
│  │                                                     │    │
│  │  Internet Gateway ←→ Route Table                   │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  S3 Bucket   │  │  CloudWatch  │  │  IAM Roles   │     │
│  │  (Artifacts) │  │  (Logs)      │  │  & Policies  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Remote State Storage                      │
│  ┌──────────────┐           ┌──────────────┐               │
│  │  S3 Bucket   │           │  DynamoDB    │               │
│  │  (TF State)  │           │  (Locking)   │               │
│  └──────────────┘           └──────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Components

### Infrastructure
- **VPC**: Isolated network with public subnet
- **EC2**: Web server running Flask application
- **S3**: Encrypted bucket for artifacts and logs
- **IAM**: Roles and policies for secure access
- **CloudWatch**: Log aggregation and monitoring
- **Security Groups**: Network access control

### Application
- **Flask Web App**: Simple REST API with health checks
- **CloudWatch Agent**: Automatic log shipping
- **Systemd Service**: Auto-start and restart capabilities

### CI/CD Pipeline
- **Validation**: Format check, init, and validate
- **Plan**: Automatic plan generation for both environments
- **Apply**: Manual approval required for production
- **Multi-Environment**: Separate dev and prod workflows

## 🚀 Quick Start

### Prerequisites
- AWS Account with appropriate permissions
- AWS CLI configured
- Terraform >= 1.0
- Git

### Initial Setup

1. **Clone the repository**
```bash
git clone <repository-url>
cd project
```

2. **Create S3 bucket for Terraform state** (one-time setup)
```bash
aws s3api create-bucket \
  --bucket terraform-state-prod-infra-2024 \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket terraform-state-prod-infra-2024 \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket terraform-state-prod-infra-2024 \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

3. **Create DynamoDB table for state locking** (one-time setup)
```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### Local Deployment

#### Deploy to Dev Environment
```bash
cd terraform
terraform init
terraform workspace new dev
terraform workspace select dev
terraform plan
terraform apply
```

#### Deploy to Prod Environment
```bash
terraform workspace new prod
terraform workspace select prod
terraform plan
terraform apply
```

### Access the Application
After deployment, get the application URL:
```bash
terraform output application_url
```

Test the endpoints:
```bash
# Health check
curl http://<instance-ip>:5000/health

# Main endpoint
curl http://<instance-ip>:5000/
```

## 🔄 CI/CD Pipeline Flow

### Pipeline Stages

```
┌─────────────┐
│   Commit    │
│  to Branch  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Validate   │
│  - Format   │
│  - Init     │
│  - Validate │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Plan     │
│  Generate   │
│  Execution  │
│    Plan     │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Manual    │  ← Required for Prod
│  Approval   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Apply    │
│  Execute    │
│    Plan     │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Deployed   │
└─────────────┘
```

### Branch Strategy
- **develop** → Deploys to Dev environment (auto-apply)
- **main** → Deploys to Prod environment (manual approval required)

### GitHub Actions Setup

1. **Configure GitHub Secrets**
   - Go to Settings → Secrets and variables → Actions
   - Add the following secrets:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`

2. **Configure GitHub Environments**
   - Go to Settings → Environments
   - Create environments: `dev`, `prod-plan`, `prod`
   - For `prod` environment:
     - Enable "Required reviewers"
     - Add reviewers who can approve production deployments

3. **Trigger Deployment**
   - Push to `develop` branch → Auto-deploys to dev
   - Push to `main` branch → Requires approval for prod
   - Manual trigger via Actions tab → Choose environment

## 📊 Monitoring and Logs

### CloudWatch Logs
View application logs:
```bash
aws logs tail /aws/ec2/dev/application --follow
```

Or via AWS Console:
1. Navigate to CloudWatch → Log groups
2. Select `/aws/ec2/{environment}/application`
3. View log streams

### Infrastructure Outputs
```bash
cd terraform
terraform output
```

Outputs include:
- VPC ID
- Instance ID and Public IP
- Application URL
- S3 Bucket Name
- CloudWatch Log Group

## 🔐 Security Features

- ✅ Encrypted S3 buckets (AES256)
- ✅ Encrypted EBS volumes
- ✅ IAM roles with least privilege
- ✅ Security groups with minimal access
- ✅ Terraform state encryption
- ✅ State locking with DynamoDB
- ✅ VPC isolation
- ✅ No hardcoded credentials

## 🌍 Multi-Environment Configuration

Environments are managed using Terraform workspaces:

| Environment | VPC CIDR      | Instance Type | Log Retention |
|-------------|---------------|---------------|---------------|
| dev         | 10.0.0.0/16   | t2.micro      | 7 days        |
| prod        | 10.1.0.0/16   | t3.small      | 30 days       |

## 📁 Project Structure

```
project/
├── terraform/
│   ├── backend.tf          # Remote state configuration
│   ├── main.tf             # Core infrastructure
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Output values
│   └── user-data.sh        # EC2 initialization script
├── app/
│   └── app.py              # Flask application
├── .github/
│   └── workflows/
│       └── terraform.yml   # CI/CD pipeline
└── README.md               # This file
```

## 🛠️ Customization

### Modify Instance Type
Edit `terraform/variables.tf`:
```hcl
variable "instance_type" {
  default = {
    dev  = "t2.micro"
    prod = "t3.medium"  # Change this
  }
}
```

### Change AWS Region
Edit `terraform/variables.tf`:
```hcl
variable "aws_region" {
  default = "us-west-2"  # Change this
}
```

### Update Application
Modify `app/app.py` and redeploy:
```bash
terraform apply -replace=aws_instance.web
```

## 🧹 Cleanup

To destroy infrastructure:
```bash
cd terraform
terraform workspace select dev
terraform destroy

terraform workspace select prod
terraform destroy
```

## 📝 Best Practices Implemented

1. **Infrastructure as Code**: All infrastructure defined in Terraform
2. **Remote State**: Centralized state with locking
3. **Multi-Environment**: Separate dev/prod configurations
4. **CI/CD Automation**: Automated validation and deployment
5. **Manual Approval**: Production changes require approval
6. **Monitoring**: CloudWatch integration for observability
7. **Security**: Encryption, IAM roles, least privilege
8. **Documentation**: Comprehensive README and inline comments
9. **Version Control**: Git-based workflow
10. **Idempotency**: Terraform ensures consistent state

## 🐛 Troubleshooting

### Issue: Terraform state locked
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Issue: EC2 instance not accessible
- Check security group rules
- Verify instance is running: `aws ec2 describe-instances`
- Check CloudWatch logs for application errors

### Issue: Application not logging to CloudWatch
- Verify IAM role permissions
- Check CloudWatch agent status: `systemctl status amazon-cloudwatch-agent`
- Review `/var/log/amazon/amazon-cloudwatch-agent/` logs

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [CloudWatch Agent Configuration](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html)

## 📄 License

This project is provided as-is for educational and demonstration purposes.

---

**Note**: Remember to configure AWS credentials and GitHub secrets before running the pipeline. Always review Terraform plans before applying changes to production.
