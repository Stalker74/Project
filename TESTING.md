# Testing & Validation Guide

## Pre-Deployment Testing

### 1. Terraform Validation

```bash
cd terraform

# Format check
terraform fmt -check -recursive

# Initialize
terraform init -backend=false

# Validate syntax
terraform validate

# Security scan (optional - requires tfsec)
tfsec .
```

### 2. Terraform Plan Review

```bash
# Dev environment
terraform workspace select dev
terraform plan -out=tfplan

# Review plan output
terraform show tfplan

# Prod environment
terraform workspace select prod
terraform plan -out=tfplan
```

### 3. Cost Estimation (Optional)

```bash
# Using Infracost (if installed)
infracost breakdown --path terraform/
```

## Post-Deployment Testing

### 1. Infrastructure Validation

```bash
# Verify all resources created
terraform state list

# Check specific resources
terraform state show aws_vpc.main
terraform state show aws_instance.web
terraform state show aws_s3_bucket.artifacts

# Verify outputs
terraform output
```

### 2. Network Connectivity Tests

```bash
# Get instance IP
INSTANCE_IP=$(terraform output -raw instance_public_ip)

# Test ICMP (if allowed)
ping -c 4 $INSTANCE_IP

# Test SSH port
nc -zv $INSTANCE_IP 22

# Test application port
nc -zv $INSTANCE_IP 5000
```

### 3. Application Testing

```bash
# Get application URL
APP_URL=$(terraform output -raw application_url)

# Test health endpoint
curl -v $APP_URL/health

# Expected response: {"status":"ok"}

# Test main endpoint
curl -v $APP_URL/

# Expected response: JSON with status, message, timestamp, environment

# Load testing (optional - requires Apache Bench)
ab -n 100 -c 10 $APP_URL/health
```

### 4. CloudWatch Logs Validation

```bash
# Get log group name
LOG_GROUP=$(terraform output -raw cloudwatch_log_group)

# List log streams
aws logs describe-log-streams --log-group-name $LOG_GROUP

# Tail logs
aws logs tail $LOG_GROUP --follow

# Search logs
aws logs filter-log-events \
  --log-group-name $LOG_GROUP \
  --filter-pattern "ERROR"

# Verify logs are being written
curl $APP_URL/
sleep 10
aws logs tail $LOG_GROUP --since 1m
```

### 5. S3 Bucket Validation

```bash
# Get bucket name
BUCKET=$(terraform output -raw s3_bucket_name)

# Verify bucket exists
aws s3 ls s3://$BUCKET/

# Check bucket encryption
aws s3api get-bucket-encryption --bucket $BUCKET

# Check bucket versioning
aws s3api get-bucket-versioning --bucket $BUCKET

# Test write access from EC2 (SSH required)
ssh ec2-user@$INSTANCE_IP "echo 'test' | aws s3 cp - s3://$BUCKET/test.txt"
aws s3 ls s3://$BUCKET/
```

### 6. IAM Role Validation

```bash
# Get instance ID
INSTANCE_ID=$(terraform output -raw instance_id)

# Verify IAM instance profile attached
aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].IamInstanceProfile'

# Verify role permissions (from EC2)
ssh ec2-user@$INSTANCE_IP "aws sts get-caller-identity"
```

### 7. Security Group Testing

```bash
# Get security group ID
SG_ID=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
  --output text)

# Review security group rules
aws ec2 describe-security-groups --group-ids $SG_ID

# Test allowed ports
nmap -p 22,5000 $INSTANCE_IP

# Test blocked ports (should timeout)
nc -zv -w 3 $INSTANCE_IP 80
```

## CI/CD Pipeline Testing

### 1. GitHub Actions Validation

```bash
# Validate workflow syntax (requires act or GitHub CLI)
gh workflow view terraform.yml

# Test workflow locally (requires act)
act -l
```

### 2. Pipeline Trigger Tests

```bash
# Test dev deployment
git checkout develop
echo "# Test" >> README.md
git add README.md
git commit -m "Test dev pipeline"
git push

# Monitor pipeline
gh run list
gh run watch

# Test prod deployment
git checkout main
git merge develop
git push

# Verify manual approval required
gh run list --workflow=terraform.yml
```

### 3. Terraform State Lock Testing

```bash
# Terminal 1: Start apply
terraform apply

# Terminal 2: Try concurrent apply (should fail with lock error)
terraform apply

# Verify lock in DynamoDB
aws dynamodb scan --table-name terraform-state-lock
```

## Integration Testing

### 1. End-to-End Deployment Test

```bash
#!/bin/bash
set -e

echo "Starting E2E test..."

# Deploy infrastructure
cd terraform
terraform workspace select dev
terraform apply -auto-approve

# Wait for instance to be ready
sleep 60

# Get outputs
APP_URL=$(terraform output -raw application_url)
LOG_GROUP=$(terraform output -raw cloudwatch_log_group)

# Test application
echo "Testing application..."
RESPONSE=$(curl -s $APP_URL/health)
if [[ $RESPONSE == *"ok"* ]]; then
  echo "✓ Health check passed"
else
  echo "✗ Health check failed"
  exit 1
fi

# Test logging
echo "Testing CloudWatch logs..."
curl -s $APP_URL/ > /dev/null
sleep 30
LOG_COUNT=$(aws logs filter-log-events \
  --log-group-name $LOG_GROUP \
  --start-time $(($(date +%s) - 60))000 \
  --query 'events | length(@)')

if [[ $LOG_COUNT -gt 0 ]]; then
  echo "✓ Logging working"
else
  echo "✗ Logging not working"
  exit 1
fi

echo "E2E test completed successfully!"
```

### 2. Disaster Recovery Test

```bash
# Backup current state
terraform state pull > backup.tfstate

# Simulate disaster - destroy infrastructure
terraform destroy -auto-approve

# Restore from state
terraform apply -auto-approve

# Verify restoration
terraform output
```

### 3. Multi-Environment Test

```bash
# Deploy to dev
terraform workspace select dev
terraform apply -auto-approve
DEV_IP=$(terraform output -raw instance_public_ip)

# Deploy to prod
terraform workspace select prod
terraform apply -auto-approve
PROD_IP=$(terraform output -raw instance_public_ip)

# Verify different IPs
if [[ $DEV_IP != $PROD_IP ]]; then
  echo "✓ Environments isolated"
else
  echo "✗ Environments not isolated"
fi
```

## Performance Testing

### 1. Application Load Test

```bash
# Install Apache Bench
# Ubuntu: apt-get install apache2-utils
# macOS: brew install httpd

APP_URL=$(cd terraform && terraform output -raw application_url)

# Light load test
ab -n 1000 -c 10 $APP_URL/health

# Medium load test
ab -n 5000 -c 50 $APP_URL/

# Stress test
ab -n 10000 -c 100 $APP_URL/health
```

### 2. Log Ingestion Test

```bash
# Generate logs
for i in {1..100}; do
  curl -s $APP_URL/ > /dev/null
  sleep 0.1
done

# Verify all logs received
sleep 60
LOG_COUNT=$(aws logs filter-log-events \
  --log-group-name $LOG_GROUP \
  --start-time $(($(date +%s) - 120))000 \
  --query 'events | length(@)')

echo "Logs received: $LOG_COUNT"
```

## Security Testing

### 1. Port Scanning

```bash
# Scan for open ports
nmap -sV $INSTANCE_IP

# Verify only expected ports open (22, 5000)
```

### 2. SSL/TLS Testing (if configured)

```bash
# Test SSL configuration
sslscan $INSTANCE_IP:443

# Check certificate
openssl s_client -connect $INSTANCE_IP:443 -showcerts
```

### 3. IAM Policy Testing

```bash
# Test S3 access from instance
ssh ec2-user@$INSTANCE_IP "aws s3 ls"

# Test CloudWatch access
ssh ec2-user@$INSTANCE_IP "aws logs describe-log-groups"

# Test denied actions (should fail)
ssh ec2-user@$INSTANCE_IP "aws ec2 describe-instances"
```

### 4. Encryption Validation

```bash
# Verify S3 encryption
aws s3api get-bucket-encryption --bucket $BUCKET

# Verify EBS encryption
aws ec2 describe-volumes \
  --filters "Name=attachment.instance-id,Values=$INSTANCE_ID" \
  --query 'Volumes[*].Encrypted'
```

## Monitoring & Alerting Tests

### 1. CloudWatch Metrics

```bash
# Check available metrics
aws cloudwatch list-metrics \
  --namespace AWS/EC2 \
  --dimensions Name=InstanceId,Value=$INSTANCE_ID

# Get CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=$INSTANCE_ID \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### 2. Log Query Testing

```bash
# Query logs for errors
aws logs filter-log-events \
  --log-group-name $LOG_GROUP \
  --filter-pattern "ERROR"

# Query logs for specific endpoint
aws logs filter-log-events \
  --log-group-name $LOG_GROUP \
  --filter-pattern "/health"

# Get log insights
aws logs start-query \
  --log-group-name $LOG_GROUP \
  --start-time $(($(date +%s) - 3600)) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | sort @timestamp desc | limit 20'
```

## Automated Test Script

```bash
#!/bin/bash
# automated-test.sh - Complete test suite

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }

echo "Starting automated test suite..."

# Test 1: Terraform validation
echo "Test 1: Terraform validation"
cd terraform
terraform fmt -check -recursive && pass "Format check" || fail "Format check"
terraform validate && pass "Validation" || fail "Validation"

# Test 2: Infrastructure deployment
echo "Test 2: Infrastructure deployment"
terraform workspace select dev
terraform apply -auto-approve && pass "Deployment" || fail "Deployment"

# Test 3: Get outputs
echo "Test 3: Retrieving outputs"
APP_URL=$(terraform output -raw application_url)
INSTANCE_IP=$(terraform output -raw instance_public_ip)
LOG_GROUP=$(terraform output -raw cloudwatch_log_group)
BUCKET=$(terraform output -raw s3_bucket_name)

# Test 4: Network connectivity
echo "Test 4: Network connectivity"
nc -zv -w 5 $INSTANCE_IP 5000 && pass "Port 5000 accessible" || fail "Port 5000 not accessible"

# Test 5: Application health
echo "Test 5: Application health"
sleep 30  # Wait for app to start
HEALTH=$(curl -s $APP_URL/health)
[[ $HEALTH == *"ok"* ]] && pass "Health check" || fail "Health check"

# Test 6: Application response
echo "Test 6: Application response"
RESPONSE=$(curl -s $APP_URL/)
[[ $RESPONSE == *"status"* ]] && pass "Application response" || fail "Application response"

# Test 7: CloudWatch logs
echo "Test 7: CloudWatch logs"
sleep 30
LOG_COUNT=$(aws logs describe-log-streams --log-group-name $LOG_GROUP --query 'logStreams | length(@)')
[[ $LOG_COUNT -gt 0 ]] && pass "CloudWatch logs" || fail "CloudWatch logs"

# Test 8: S3 bucket
echo "Test 8: S3 bucket"
aws s3 ls s3://$BUCKET/ && pass "S3 bucket accessible" || fail "S3 bucket not accessible"

# Test 9: Encryption
echo "Test 9: Encryption"
aws s3api get-bucket-encryption --bucket $BUCKET > /dev/null && pass "S3 encryption" || fail "S3 encryption"

echo ""
echo "All tests passed! ✓"
```

## Test Checklist

- [ ] Terraform format check passes
- [ ] Terraform validation passes
- [ ] Infrastructure deploys successfully
- [ ] All outputs are generated
- [ ] Application is accessible
- [ ] Health endpoint returns 200
- [ ] Main endpoint returns valid JSON
- [ ] CloudWatch logs are being written
- [ ] S3 bucket is accessible
- [ ] S3 bucket is encrypted
- [ ] EBS volumes are encrypted
- [ ] IAM roles are attached
- [ ] Security groups are configured correctly
- [ ] Only required ports are open
- [ ] CI/CD pipeline runs successfully
- [ ] Manual approval works for prod
- [ ] State locking prevents concurrent changes
- [ ] Multi-environment isolation works
- [ ] Logs are searchable in CloudWatch
- [ ] Application handles load appropriately

## Troubleshooting Failed Tests

### Application Not Accessible
```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids $INSTANCE_ID

# Check system log
aws ec2 get-console-output --instance-id $INSTANCE_ID

# Check security group
aws ec2 describe-security-groups --group-ids $SG_ID
```

### Logs Not Appearing
```bash
# SSH to instance
ssh ec2-user@$INSTANCE_IP

# Check CloudWatch agent
sudo systemctl status amazon-cloudwatch-agent

# Check agent logs
sudo cat /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Check application logs locally
sudo tail -f /var/log/app.log
```

### Terraform Apply Fails
```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform apply

# Check state
terraform state list

# Validate configuration
terraform validate
```

## Continuous Testing

Set up automated testing in CI/CD:

```yaml
# Add to .github/workflows/terraform.yml
test:
  name: Run Tests
  needs: apply-dev
  runs-on: ubuntu-latest
  steps:
    - name: Run automated tests
      run: bash automated-test.sh
```

---

**Remember**: Always test in dev before deploying to prod!
