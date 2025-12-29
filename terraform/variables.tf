variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2" # Sydney
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "jira"
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# EC2 Variables
variable "instance_type" {
  description = "EC2 instance type for Jira server"
  type        = string
  default     = "t3.medium" # 2 vCPU, 4GB RAM
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = ""
}

variable "jira_data_volume_size" {
  description = "Size of EBS volume for Jira data in GB"
  type        = number
  default     = 20 # Reduced for small team
}

# RDS Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro" # Optimized for ~20 users
}

variable "db_name" {
  description = "Name of the Jira database"
  type        = string
  default     = "jiradb"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "jiraadmin"
}

variable "db_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS autoscaling in GB"
  type        = number
  default     = 100
}

# Jira Configuration
variable "jira_version" {
  description = "Jira Software version"
  type        = string
  default     = "9.12.0"
}

variable "jira_memory" {
  description = "JVM memory for Jira (e.g., 2048m)"
  type        = string
  default     = "1536m" # 1.5GB optimized for small team
}

# Domain and SSL
variable "domain_name" {
  description = "Domain name for Jira (e.g., jira.example.com)"
  type        = string
  default     = ""
}

variable "subject_alternative_names" {
  description = "Additional domain names for the SSL certificate"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for DNS validation and A record creation"
  type        = string
  default     = ""
}

variable "create_route53_record" {
  description = "Whether to create Route 53 A record pointing to ALB"
  type        = bool
  default     = true
}

# GitHub Repository (for downloading agent JAR)
variable "github_repo" {
  description = "GitHub repository in format owner/repo"
  type        = string
  default     = "kingnnt/jira-crack"  # Update with your repo
}

variable "github_branch" {
  description = "GitHub branch to download files from"
  type        = string
  default     = "master"
}

# Access Control
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access Jira"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_allowed_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = []
}
