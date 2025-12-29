# Jira on AWS with Docker - Terraform

Terraform configuration to deploy Atlassian Jira Software on AWS using Docker.
**Optimized for Vietnam region (Singapore) and small teams (~20 users).**

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                            VPC                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   Public Subnets                         │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │    │
│  │  │     IGW     │  │     ALB     │  │ EC2 (Jira)      │  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   Private Subnets                        │    │
│  │                 ┌───────────────────────┐                │    │
│  │                 │   RDS PostgreSQL      │                │    │
│  │                 └───────────────────────┘                │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Cost Estimate (~$72/month)

| Component | Spec | Monthly Cost (USD) |
|-----------|------|-------------------|
| EC2 | t3.medium (2 vCPU, 4GB) | ~$30 |
| RDS | db.t3.micro (2 vCPU, 1GB) | ~$13 |
| ALB | Application Load Balancer | ~$20 |
| EBS | 40GB gp3 | ~$4 |
| Data Transfer | ~50GB/month | ~$5 |

## CI/CD with GitHub Actions

The project includes automated deployment via GitHub Actions.

### Setup GitHub Actions

1. **Create S3 bucket for Terraform state:**
   ```bash
   # Replace YOUR_ACCOUNT_ID with your AWS account ID
   aws s3api create-bucket \
     --bucket jira-terraform-state \
     --region ap-southeast-1 \
     --create-bucket-configuration LocationConstraint=ap-southeast-1

   aws s3api put-bucket-versioning \
     --bucket jira-terraform-state \
     --versioning-configuration Status=Enabled
   ```

2. **Create DynamoDB table for state locking:**
   ```bash
   aws dynamodb create-table \
     --table-name jira-terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region ap-southeast-1
   ```

3. **Add GitHub Secrets:**

   Go to your GitHub repo → Settings → Secrets and variables → Actions

   | Secret | Description |
   |--------|-------------|
   | `AWS_ACCESS_KEY_ID` | AWS access key |
   | `AWS_SECRET_ACCESS_KEY` | AWS secret key |
   | `DB_PASSWORD` | Secure password for RDS |

4. **Update backend.tf:**

   Edit `terraform/backend.tf` and set your S3 bucket name.

5. **Push to master:**
   ```bash
   git add .
   git commit -m "Initial Jira infrastructure"
   git push origin master
   ```

### Workflow Behavior

| Event | Action |
|-------|--------|
| Push to `master` | `terraform apply` (auto-deploy) |
| Pull Request to `master` | `terraform plan` (comment on PR) |

## Manual Deployment

```bash
cd terraform

# Initialize (first time only)
terraform init

# Plan
terraform plan -var="db_password=YourSecurePassword"

# Apply
terraform apply -var="db_password=YourSecurePassword"
```

## Configuration

### Required Secrets (GitHub Actions)

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `DB_PASSWORD` | RDS database password |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `instance_type` | t3.medium | EC2 instance type |
| `db_instance_class` | db.t3.micro | RDS instance class |
| `jira_version` | 9.12.0 | Jira version |
| `jira_memory` | 1536m | JVM memory |
| `domain_name` | - | Custom domain |
| `certificate_arn` | - | ACM cert for HTTPS |

## Accessing Jira

After deployment:

```bash
# Get Jira URL
terraform output jira_url

# Connect to instance via SSM
aws ssm start-session --target $(terraform output -raw jira_instance_id)
```

## Troubleshooting

### View Jira logs
```bash
# Connect via SSM first
docker logs -f jira
```

### Restart Jira
```bash
cd /opt/jira && docker-compose restart
```

### Rebuild Jira image
```bash
cd /opt/jira/build
docker build -t jira-custom:9.12.0 .
cd /opt/jira && docker-compose up -d
```

## Cleanup

```bash
terraform destroy -var="db_password=xxx"
```
