# Architecture Diagrams

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud Account                           │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │                    VPC (10.0.0.0/16 or 10.1.0.0/16)            │   │
│  │                                                                 │   │
│  │  ┌──────────────────────────────────────────────────────┐     │   │
│  │  │  Public Subnet (10.x.1.0/24)                         │     │   │
│  │  │                                                       │     │   │
│  │  │  ┌─────────────────────────────────────────────┐    │     │   │
│  │  │  │  EC2 Instance (t2.micro/t3.small)           │    │     │   │
│  │  │  │  ┌───────────────────────────────────────┐  │    │     │   │
│  │  │  │  │  Flask Application (Port 5000)        │  │    │     │   │
│  │  │  │  │  - REST API                           │  │    │     │   │
│  │  │  │  │  - Health Checks                      │  │    │     │   │
│  │  │  │  │  - JSON Responses                     │  │    │     │   │
│  │  │  │  └───────────────────────────────────────┘  │    │     │   │
│  │  │  │  ┌───────────────────────────────────────┐  │    │     │   │
│  │  │  │  │  CloudWatch Agent                     │  │    │     │   │
│  │  │  │  │  - Log Collection                     │  │    │     │   │
│  │  │  │  │  - Metric Collection                  │  │    │     │   │
│  │  │  │  └───────────────────────────────────────┘  │    │     │   │
│  │  │  │  ┌───────────────────────────────────────┐  │    │     │   │
│  │  │  │  │  IAM Instance Profile                 │  │    │     │   │
│  │  │  │  │  - S3 Access                          │  │    │     │   │
│  │  │  │  │  - CloudWatch Access                  │  │    │     │   │
│  │  │  │  └───────────────────────────────────────┘  │    │     │   │
│  │  │  └─────────────────────────────────────────────┘    │     │   │
│  │  │                                                       │     │   │
│  │  │  Security Group: {env}-web-sg                        │     │   │
│  │  │  - Inbound: 22 (SSH), 5000 (HTTP)                   │     │   │
│  │  │  - Outbound: All                                     │     │   │
│  │  └──────────────────────────────────────────────────────┘     │   │
│  │                                                                 │   │
│  │  ┌──────────────────┐                                          │   │
│  │  │ Internet Gateway │                                          │   │
│  │  └────────┬─────────┘                                          │   │
│  │           │                                                     │   │
│  │  ┌────────▼─────────┐                                          │   │
│  │  │   Route Table    │                                          │   │
│  │  │  0.0.0.0/0 → IGW │                                          │   │
│  │  └──────────────────┘                                          │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐   │
│  │   S3 Bucket      │  │  CloudWatch      │  │   IAM Roles      │   │
│  │                  │  │                  │  │                  │   │
│  │  - Artifacts     │  │  - Log Groups    │  │  - EC2 Role      │   │
│  │  - Logs          │  │  - Log Streams   │  │  - Policies      │   │
│  │  - Versioned     │  │  - Metrics       │  │  - Permissions   │   │
│  │  - Encrypted     │  │  - Insights      │  │                  │   │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                      Terraform State Management                          │
│                                                                          │
│  ┌──────────────────────────┐      ┌──────────────────────────┐        │
│  │  S3 Bucket               │      │  DynamoDB Table          │        │
│  │  terraform-state-*       │      │  terraform-state-lock    │        │
│  │                          │      │                          │        │
│  │  - State Files           │      │  - Lock Records          │        │
│  │  - Versioning Enabled    │      │  - Prevents Concurrent   │        │
│  │  - Encryption Enabled    │      │    Modifications         │        │
│  └──────────────────────────┘      └──────────────────────────┘        │
└─────────────────────────────────────────────────────────────────────────┘
```

## Network Flow Diagram

```
Internet
    │
    │ HTTPS/HTTP
    ▼
┌─────────────────────────────────────────┐
│         Internet Gateway                 │
└─────────────────┬───────────────────────┘
                  │
                  │
┌─────────────────▼───────────────────────┐
│          Route Table                     │
│     0.0.0.0/0 → Internet Gateway        │
└─────────────────┬───────────────────────┘
                  │
                  │
┌─────────────────▼───────────────────────┐
│       Public Subnet (10.x.1.0/24)       │
│                                          │
│  ┌────────────────────────────────┐    │
│  │    Security Group              │    │
│  │    - Allow 22 (SSH)            │    │
│  │    - Allow 5000 (App)          │    │
│  └────────────┬───────────────────┘    │
│               │                         │
│  ┌────────────▼───────────────────┐    │
│  │      EC2 Instance              │    │
│  │      Flask App :5000           │    │
│  └────────────┬───────────────────┘    │
│               │                         │
└───────────────┼─────────────────────────┘
                │
                ├──────────► S3 Bucket (Artifacts)
                │
                └──────────► CloudWatch Logs
```

## CI/CD Pipeline Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Developer Workflow                            │
└──────────────────────────────────────────────────────────────────────┘
                                │
                                │ git push
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│                          GitHub Repository                            │
│                                                                       │
│  ┌─────────────┐                    ┌─────────────┐                 │
│  │   develop   │                    │     main    │                 │
│  │   branch    │                    │    branch   │                 │
│  └──────┬──────┘                    └──────┬──────┘                 │
└─────────┼──────────────────────────────────┼────────────────────────┘
          │                                   │
          │ Trigger                           │ Trigger
          ▼                                   ▼
┌─────────────────────┐            ┌─────────────────────┐
│  GitHub Actions     │            │  GitHub Actions     │
│  (Dev Pipeline)     │            │  (Prod Pipeline)    │
└─────────────────────┘            └─────────────────────┘
          │                                   │
          ▼                                   ▼
┌─────────────────────┐            ┌─────────────────────┐
│  1. Validate        │            │  1. Validate        │
│     - Format Check  │            │     - Format Check  │
│     - Syntax Check  │            │     - Syntax Check  │
└──────────┬──────────┘            └──────────┬──────────┘
           │                                   │
           ▼                                   ▼
┌─────────────────────┐            ┌─────────────────────┐
│  2. Plan            │            │  2. Plan            │
│     - terraform     │            │     - terraform     │
│       workspace     │            │       workspace     │
│       select dev    │            │       select prod   │
│     - terraform     │            │     - terraform     │
│       plan          │            │       plan          │
└──────────┬──────────┘            └──────────┬──────────┘
           │                                   │
           │ Auto                              │
           ▼                                   ▼
┌─────────────────────┐            ┌─────────────────────┐
│  3. Apply           │            │  3. Manual Approval │
│     - terraform     │            │     ⚠️  REQUIRED   │
│       apply         │            │                     │
│       -auto-approve │            └──────────┬──────────┘
└──────────┬──────────┘                       │
           │                                   │ Approved
           │                                   ▼
           │                        ┌─────────────────────┐
           │                        │  4. Apply           │
           │                        │     - terraform     │
           │                        │       apply         │
           │                        │       -auto-approve │
           │                        └──────────┬──────────┘
           │                                   │
           ▼                                   ▼
┌─────────────────────┐            ┌─────────────────────┐
│  Dev Environment    │            │  Prod Environment   │
│  Deployed ✓         │            │  Deployed ✓         │
└─────────────────────┘            └─────────────────────┘
```

## Data Flow Diagram

```
┌──────────────┐
│   End User   │
└──────┬───────┘
       │ HTTP Request
       │ GET /health or /
       ▼
┌──────────────────────────────┐
│  EC2 Instance                │
│  ┌────────────────────────┐  │
│  │  Flask Application     │  │
│  │  - Receives request    │  │
│  │  - Processes logic     │  │
│  │  - Generates response  │  │
│  └───────┬────────────────┘  │
│          │                   │
│          │ Write log         │
│          ▼                   │
│  ┌────────────────────────┐  │
│  │  /var/log/app.log      │  │
│  └───────┬────────────────┘  │
│          │                   │
└──────────┼───────────────────┘
           │
           │ CloudWatch Agent
           │ reads and ships
           ▼
┌──────────────────────────────┐
│  CloudWatch Logs             │
│  /aws/ec2/{env}/application  │
│  - Log Streams               │
│  - Log Events                │
│  - Searchable                │
└──────────────────────────────┘
           │
           │ Query/View
           ▼
┌──────────────────────────────┐
│  CloudWatch Console          │
│  or AWS CLI                  │
└──────────────────────────────┘
```

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Security Layers                           │
└─────────────────────────────────────────────────────────────────┘

Layer 1: Network Security
┌─────────────────────────────────────────────────────────────────┐
│  VPC Isolation                                                   │
│  - Private IP space (10.x.0.0/16)                               │
│  - Network ACLs                                                  │
│  - Security Groups (Stateful Firewall)                          │
│    • Inbound: Only 22, 5000                                     │
│    • Outbound: All (for updates, AWS API)                       │
└─────────────────────────────────────────────────────────────────┘

Layer 2: Identity & Access Management
┌─────────────────────────────────────────────────────────────────┐
│  IAM Roles & Policies                                            │
│  - EC2 Instance Profile                                          │
│    • S3 Read/Write (specific bucket only)                       │
│    • CloudWatch Logs Write                                       │
│    • No EC2 permissions (least privilege)                       │
│  - No long-term credentials on instance                         │
└─────────────────────────────────────────────────────────────────┘

Layer 3: Data Encryption
┌─────────────────────────────────────────────────────────────────┐
│  Encryption at Rest                                              │
│  - S3 Bucket: AES-256 encryption                                │
│  - EBS Volume: Encrypted                                         │
│  - Terraform State: Encrypted in S3                             │
│                                                                  │
│  Encryption in Transit                                           │
│  - AWS API calls: TLS                                           │
│  - CloudWatch Agent: TLS                                         │
└─────────────────────────────────────────────────────────────────┘

Layer 4: State Security
┌─────────────────────────────────────────────────────────────────┐
│  Terraform State Protection                                      │
│  - Remote state in S3 (not local)                               │
│  - State locking with DynamoDB                                   │
│  - Versioning enabled                                            │
│  - Encrypted storage                                             │
└─────────────────────────────────────────────────────────────────┘

Layer 5: Access Control
┌─────────────────────────────────────────────────────────────────┐
│  Deployment Controls                                             │
│  - GitHub Secrets for credentials                               │
│  - Environment protection rules                                  │
│  - Manual approval for production                               │
│  - Audit trail in GitHub Actions                                │
└─────────────────────────────────────────────────────────────────┘
```

## Multi-Environment Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Terraform Workspace: dev                          │
│                                                                      │
│  VPC: 10.0.0.0/16                                                   │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  Subnet: 10.0.1.0/24                                        │    │
│  │  ┌──────────────────────────────────────────────────┐      │    │
│  │  │  EC2: t2.micro (Free Tier)                       │      │    │
│  │  │  - Development workload                          │      │    │
│  │  │  - Lower resources                               │      │    │
│  │  │  - 7-day log retention                           │      │    │
│  │  └──────────────────────────────────────────────────┘      │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  S3: dev-app-artifacts-{account-id}                                 │
│  CloudWatch: /aws/ec2/dev/application                               │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    Terraform Workspace: prod                         │
│                                                                      │
│  VPC: 10.1.0.0/16                                                   │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  Subnet: 10.1.1.0/24                                        │    │
│  │  ┌──────────────────────────────────────────────────┐      │    │
│  │  │  EC2: t3.small (Production)                      │      │    │
│  │  │  - Production workload                           │      │    │
│  │  │  - Higher resources                              │      │    │
│  │  │  - 30-day log retention                          │      │    │
│  │  │  - Manual approval required                      │      │    │
│  │  └──────────────────────────────────────────────────┘      │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  S3: prod-app-artifacts-{account-id}                                │
│  CloudWatch: /aws/ec2/prod/application                              │
└─────────────────────────────────────────────────────────────────────┘

                    Shared Resources
┌─────────────────────────────────────────────────────────────────────┐
│  S3: terraform-state-prod-infra-2024                                │
│  DynamoDB: terraform-state-lock                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Monitoring & Observability

```
┌──────────────────────────────────────────────────────────────────┐
│                      Monitoring Stack                             │
└──────────────────────────────────────────────────────────────────┘

Application Layer
┌──────────────────────────────────────────────────────────────────┐
│  Flask Application                                                │
│  └─► Python Logging                                              │
│      └─► /var/log/app.log                                        │
│          - Request logs                                           │
│          - Error logs                                             │
│          - Application events                                     │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         │ CloudWatch Agent
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│  CloudWatch Logs                                                  │
│  /aws/ec2/{env}/application                                      │
│  - Real-time log ingestion                                        │
│  - Log retention policies                                         │
│  - Log Insights queries                                           │
│  - Metric filters                                                 │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│  CloudWatch Metrics                                               │
│  - CPU Utilization                                                │
│  - Network In/Out                                                 │
│  - Disk I/O                                                       │
│  - Custom application metrics                                     │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│  CloudWatch Dashboards (Optional)                                 │
│  - Visual representation                                          │
│  - Real-time monitoring                                           │
│  - Alerting (can be added)                                        │
└──────────────────────────────────────────────────────────────────┘
```

## Deployment State Machine

```
┌─────────┐
│  Start  │
└────┬────┘
     │
     ▼
┌─────────────────┐
│ terraform init  │
└────┬────────────┘
     │
     ▼
┌─────────────────────┐
│ workspace select    │
│ (dev or prod)       │
└────┬────────────────┘
     │
     ▼
┌─────────────────┐
│ terraform plan  │
└────┬────────────┘
     │
     ▼
┌─────────────────────┐      ┌──────────┐
│ Review plan output  │─────►│  Abort   │
└────┬────────────────┘      └──────────┘
     │ Approve
     ▼
┌─────────────────┐
│ terraform apply │
└────┬────────────┘
     │
     ▼
┌─────────────────────┐
│ Resources creating  │
│ - VPC               │
│ - Subnet            │
│ - IGW               │
│ - Route Table       │
│ - Security Group    │
│ - IAM Role          │
│ - S3 Bucket         │
│ - CloudWatch Logs   │
│ - EC2 Instance      │
└────┬────────────────┘
     │
     ▼
┌─────────────────────┐
│ User Data Execution │
│ - Install packages  │
│ - Configure CW Agent│
│ - Deploy app        │
│ - Start service     │
└────┬────────────────┘
     │
     ▼
┌─────────────────┐
│ Infrastructure  │
│    Ready ✓      │
└─────────────────┘
```

---

These diagrams provide a visual representation of the complete infrastructure,
data flows, security layers, and deployment processes.
