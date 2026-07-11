# 3-Tier AWS Architecture

A Terraform-managed, highly available 3-tier AWS architecture for running a containerized web application. The default development environment deploys into `eu-west-2` across two Availability Zones, with separate public, frontend, backend, and database network tiers.

The project is organized with reusable Terraform modules and an environment layer under `Environments/Development` that wires the modules together for a complete application stack.

## Architecture Diagram

![Architecture Diagram](images/architecture.png)

## Architecture Overview

This stack separates traffic, compute, and data into clear tiers:

1. Users access the application through an internet-facing Application Load Balancer.
2. The external ALB forwards HTTP traffic to frontend EC2 instances running in private frontend subnets.
3. Frontend instances call the backend through an internal Application Load Balancer.
4. The internal ALB forwards requests to backend EC2 instances running in private backend subnets.
5. Backend instances connect to a private PostgreSQL RDS database in isolated database subnets.
6. A bastion host in a public subnet provides controlled SSH access to private instances from the configured allowed IP range.

## AWS Services Used

- Amazon VPC
- Public and private subnets
- Internet Gateway
- NAT Gateways
- Route tables
- Security Groups
- EC2
- Auto Scaling Groups
- Application Load Balancers
- Amazon RDS for PostgreSQL
- AWS Secrets Manager
- IAM roles and instance profiles
- Amazon S3 for Terraform state
- DynamoDB for Terraform state locking
- CloudWatch metrics and alarms

## Network Layout

The development environment creates one VPC with eight subnets across two Availability Zones:

| Tier | Subnets | Purpose |
| --- | --- | --- |
| Public | 2 | Internet-facing ALB, bastion host, NAT gateways |
| Frontend private | 2 | Frontend application instances |
| Backend private | 2 | Backend application instances |
| Database | 2 | PostgreSQL RDS subnet group |

Routing is split by tier:

- Public subnets route outbound traffic through the Internet Gateway.
- Frontend and backend private subnets route outbound internet traffic through NAT gateways.
- Database subnets use a separate route table with no internet route.

## Traffic Flow and Security

Security Groups define the main network boundaries:

| Source | Destination | Port | Purpose |
| --- | --- | --- | --- |
| Internet | External ALB | `80`, `443` | Public application entry point |
| External ALB SG | Frontend instances | `3000` | Frontend container traffic |
| Frontend SG | Internal ALB | `80` | Private frontend-to-backend entry point |
| Internal ALB SG | Backend instances | `8080` | Backend container traffic |
| Backend SG | RDS PostgreSQL | `5432` | Database access |
| Allowed IP range | Bastion host | `22` | SSH entry point |
| Bastion SG | Frontend/backend instances | `22` | Private instance administration |

The ALB target groups use `/health` as the health check path. HTTPS listeners are supported by the ALB module when a certificate ARN is provided.

## Terraform Structure

| Path | Description |
| --- | --- |
| `Environments/Development` | Main development environment that composes all modules |
| `Environments/Development/backend` | Bootstrap stack for remote Terraform state |
| `Modules/VPC` | VPC, subnets, Internet Gateway, NAT gateways, and route tables |
| `Modules/SG` | Security Groups for ALBs, EC2 tiers, RDS, and bastion access |
| `Modules/ALB` | External and internal Application Load Balancers, listeners, and target groups |
| `Modules/ASG` | Launch templates, Auto Scaling Groups, scaling policies, and CloudWatch alarms |
| `Modules/RDS` | PostgreSQL RDS instance, subnet group, parameter group, backups, and encryption |
| `Modules/SECRETS` | Secrets Manager secret for database connection details |
| `Modules/IAM` | EC2 role, instance profile, SSM, CloudWatch, Secrets Manager, and ECR permissions |
| `Modules/BASTIAN` | Bastion EC2 instance with Elastic IP |

## Remote State

The backend bootstrap stack in `Environments/Development/backend` creates:

- An encrypted S3 bucket with versioning enabled for Terraform state.
- A DynamoDB table for state locking.

The main environment declares `backend "s3" {}` in `Environments/Development/versions.tf`. After bootstrapping the backend resources, initialize the main environment with the generated bucket and lock table details.

Example backend initialization:

```bash
cd Environments/Development

terraform init \
  -backend-config="bucket=<state-bucket-name>" \
  -backend-config="key=development/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=aws-3tier-architeture-dev-tfstate-locks"
```

The backend bootstrap stack currently creates its state bucket in `us-east-1`, while the application stack defaults to `eu-west-2`.

## Prerequisites

- Terraform `>= 1.10.0`
- AWS CLI configured with credentials for the target AWS account
- Docker, if you need to build and push the frontend/backend images
- An SSH key pair for EC2 access
- AWS permissions to create VPC, EC2, ALB, RDS, IAM, S3, DynamoDB, Secrets Manager, and CloudWatch resources

## Setup

### 1. Create an SSH key

```bash
ssh-keygen -t ed25519 -C "aws-ec2-key"
```

The current environment creates an AWS key pair named `aws-ec2-key` from `/home/awais/.ssh/aws-ec2-key.pub`. Update `Environments/Development/main.tf` if you want to use a different public key path or key name.

### 2. Build and push Docker images

Build and push both application images before applying the Terraform stack.

```bash
docker login

# Frontend
docker build -t "<dockerhub-user>/<frontend-image>:<tag>" .
docker push "<dockerhub-user>/<frontend-image>:<tag>"

# Backend
docker build -t "<dockerhub-user>/<backend-image>:<tag>" .
docker push "<dockerhub-user>/<backend-image>:<tag>"
```

### 3. Configure variables

Update values in `Environments/Development/variables.tf` or pass them through a `.tfvars` file:

- `frontend_docker_image`
- `backend_docker_image`
- `dockerhub_username`
- `dockerhub_password`, if private images require Docker Hub login
- `allowed_IPs`
- Database settings such as `db_username`, `db_name`, `db_instance_class`, and backup settings
- ASG sizes for frontend and backend capacity

For SSH access, set `allowed_IPs` to your public IP in CIDR format, for example:

```hcl
allowed_IPs = "203.0.113.10/32"
```

### 4. Configure AWS CLI

```bash
aws configure
```

Confirm the configured account and identity before creating resources:

```bash
aws sts get-caller-identity
```

### 5. Bootstrap Terraform remote state

```bash
cd Environments/Development/backend

terraform init
terraform validate
terraform plan
terraform apply
```

Use the resulting S3 bucket name and DynamoDB table name when initializing the main environment.

### 6. Deploy the application environment

```bash
cd Environments/Development

terraform init \
  -backend-config="bucket=<state-bucket-name>" \
  -backend-config="key=development/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=aws-3tier-architeture-dev-tfstate-locks"

terraform validate
terraform plan
terraform apply
```

## Useful Outputs

After deployment, Terraform exposes values that help with access and operations:

| Output | Description |
| --- | --- |
| `application_url` | Public URL for the external ALB |
| `alb_dns_name` | DNS name of the internet-facing ALB |
| `bastion_public_ip` | Public IP address for SSH access through the bastion host |
| `frontend_asg_name` | Frontend Auto Scaling Group name |
| `backend_asg_name` | Backend Auto Scaling Group name |
| `db_secret_name` | Secrets Manager secret containing database connection details |
| `db_endpoint` | RDS endpoint, marked sensitive |

Show outputs with:

```bash
terraform output
```

For sensitive values:

```bash
terraform output db_endpoint
```

## Operations and Troubleshooting

### SSH through the bastion host

```bash
ssh -i "<key_name>" ubuntu@"<bastion_public_ip>"
```

To connect from the bastion host to a private frontend or backend instance:

```bash
scp -i "<key_name>" "<key_name>" ubuntu@"<bastion_public_ip>":~/
ssh -i "<key_name>" ubuntu@"<private_instance_ip>"
```

### Check Docker containers

```bash
docker ps
docker logs "<container_id>"
```

### Check EC2 user-data logs

```bash
cat /var/log/cloud-init-output.log
```

### Check ALB health

If instances are not receiving traffic, verify:

- The application exposes `/health`.
- Frontend containers listen on port `3000`.
- Backend containers listen on port `8080`.
- Target groups show healthy registered targets.
- Security Groups match the expected source and destination rules.

### Check database connectivity

If the backend cannot connect to RDS, verify:

- The backend instances can read the database secret from Secrets Manager.
- The RDS Security Group allows port `5432` from the backend Security Group.
- The database is deployed in the expected private database subnets.
- The backend container is using the secret values for host, port, username, password, and database name.

## Cleanup

Destroy the main application stack first:

```bash
cd Environments/Development
terraform destroy
```

Then destroy the remote-state bootstrap stack only when you no longer need the stored Terraform state:

```bash
cd Environments/Development/backend
terraform destroy
```

This project can create billable AWS resources, including NAT gateways, Application Load Balancers, EC2 instances, RDS, S3, DynamoDB, and CloudWatch resources. Destroy unused environments to avoid ongoing cost.

## Known Notes

- `Modules/ASG` expects user-data scripts at `Scripts/frontend_user_data.sh` and `Scripts/backend_user_data.sh`. Those scripts are referenced by Terraform but are not present in the current repo listing.
- The IDE-opened `Environments/Development/provider.tf` file is not present in the current workspace. The provider and backend configuration currently live in `Environments/Development/versions.tf`.
