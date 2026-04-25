# Auto Scaling Group Module

This Terraform module creates an EC2 Auto Scaling Group for either the frontend or backend layer of the three-tier AWS application.

It builds a launch template, attaches instances to an Application Load Balancer target group, configures scaling based on average CPU utilization, and creates CloudWatch alarms for operational monitoring.

## Resources Created

- `aws_ami.ubuntu` data source for the latest Ubuntu 22.04 LTS AMI when no custom AMI is provided.
- `aws_launch_template.lt` for EC2 instance configuration.
- `aws_autoscaling_group.asg` for frontend or backend EC2 instances.
- `aws_autoscaling_policy.cpu` target tracking policy for CPU-based scaling.
- `aws_cloudwatch_metric_alarm.high_cpu` alarm when EC2 CPU usage is above 70%.
- `aws_cloudwatch_metric_alarm.frontend_unhealthy` alarm for unhealthy frontend ALB targets.

## How It Works

The module uses the `front_back` variable to decide which user data script to run:

- `frontend` uses `Scripts/frontend_user_data.sh`
- `backend` uses `Scripts/backend_user_data.sh`

The selected script is rendered with Terraform `templatefile()` and passed into the launch template as base64-encoded user data.

Instances are launched into the supplied private subnet IDs and registered with the supplied ALB target group ARN. The Auto Scaling Group uses ELB health checks with a 300 second grace period.

## Example Usage

### Frontend ASG

```hcl
module "frontend_asg" {
  source = "../../Modules/ASG"

  environment = var.environment
  region      = var.region
  project     = var.project

  front_back    = "frontend"
  instance_type = var.frontend_instance_type
  key_name      = aws_key_pair.deployer.key_name

  subnet_ids           = module.vpc.frontend_subnet_ids
  security_group_id    = module.security_groups.frontend_sgid
  target_group_arns    = module.external_alb.target_group_arn
  iam_instance_profile = module.iam.ec2_instance_profile_name

  min_size         = var.frontend_min_size
  max_size         = var.frontend_max_size
  desired_capacity = var.frontend_desired_capacity

  docker_image       = var.frontend_docker_image
  dockerhub_username = var.dockerhub_username
  dockerhub_password = var.dockerhub_password

  db_secret_arn        = module.secrets.db_secret_arn
  backend_internal_url = "http://${module.internal_alb.alb_dns_name}"
}
```

### Backend ASG

```hcl
module "backend_asg" {
  source = "../../Modules/ASG"

  environment = var.environment
  region      = var.region
  project     = var.project

  front_back    = "backend"
  instance_type = var.backend_instance_type
  key_name      = aws_key_pair.deployer.key_name

  subnet_ids           = module.vpc.backend_subnet_ids
  security_group_id    = module.security_groups.backend_sgid
  target_group_arns    = module.internal_alb.target_group_arn
  iam_instance_profile = module.iam.ec2_instance_profile_name

  min_size         = var.backend_min_size
  max_size         = var.backend_max_size
  desired_capacity = var.backend_desired_capacity

  docker_image       = var.backend_docker_image
  dockerhub_username = var.dockerhub_username
  dockerhub_password = var.dockerhub_password

  db_secret_arn        = module.secrets.db_secret_arn
  backend_internal_url = "http://${module.internal_alb.alb_dns_name}"
}
```

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `environment` | `string` | n/a | Environment name, such as `dev`, `staging`, or `prod`. |
| `ami_id` | `string` | `""` | Optional custom AMI ID. If empty, the latest Ubuntu 22.04 AMI is used. |
| `key_name` | `string` | n/a | EC2 key pair name used for SSH access. |
| `iam_instance_profile` | `string` | n/a | IAM instance profile name attached to EC2 instances. |
| `instance_type` | `string` | n/a | EC2 instance type for the launch template. |
| `security_group_id` | `string` | n/a | Security group ID attached to EC2 instances. |
| `docker_image` | `string` | n/a | Docker image pulled and started by the user data script. |
| `dockerhub_username` | `string` | n/a | Docker Hub username for private images. Leave empty for public images. |
| `dockerhub_password` | `string` | n/a | Docker Hub password or token for private images. Leave empty for public images. |
| `db_secret_arn` | `string` | n/a | AWS Secrets Manager secret ARN containing database connection details. |
| `region` | `string` | n/a | AWS region used by the user data scripts. |
| `project` | `string` | n/a | Project name used in resource names and tags. |
| `min_size` | `number` | n/a | Minimum number of EC2 instances in the Auto Scaling Group. |
| `max_size` | `number` | n/a | Maximum number of EC2 instances in the Auto Scaling Group. |
| `desired_capacity` | `number` | n/a | Desired number of EC2 instances. |
| `subnet_ids` | `list(string)` | n/a | Subnet IDs where ASG instances are launched. |
| `target_group_arns` | `string` | n/a | ALB target group ARN attached to the Auto Scaling Group. |
| `alarm_actions` | `list(string)` | `[]` | Optional CloudWatch alarm action ARNs, such as SNS topic ARNs. |
| `backend_internal_url` | `string` | n/a | Internal backend ALB URL used by the frontend user data script. |
| `front_back` | `string` | n/a | Application tier selector. Use `frontend` or `backend`. |

## Outputs

| Name | Description |
| --- | --- |
| `asg_id` | ID of the Auto Scaling Group. |
| `asg_name` | Name of the Auto Scaling Group. |
| `asge_arn` | ARN of the Auto Scaling Group. |
| `launch_template_id` | ID of the launch template. |
| `launch_template_latest_version` | Latest launch template version. |

## Notes

- The launch template enables IMDSv2 by setting `http_tokens = "required"`.
- EC2 detailed monitoring is enabled in the launch template.
- Root EBS volumes are encrypted `gp3` volumes with a size of 20 GiB.
- The ASG scaling policy targets 70% average CPU utilization.
- The frontend-only unhealthy target alarm is created only when `front_back = "frontend"`.
- The module expects user data scripts to exist at `Scripts/frontend_user_data.sh` and `Scripts/backend_user_data.sh` relative to the environment root module.
