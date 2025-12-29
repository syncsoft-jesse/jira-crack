output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.jira.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer (for Route 53)"
  value       = aws_lb.jira.zone_id
}

output "jira_url" {
  description = "URL to access Jira"
  value       = var.domain_name != "" && var.route53_zone_id != "" ? "https://${var.domain_name}" : "http://${aws_lb.jira.dns_name}"
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.domain_name != "" ? aws_acm_certificate.main[0].arn : null
}

output "certificate_status" {
  description = "Status of the ACM certificate"
  value       = var.domain_name != "" ? aws_acm_certificate.main[0].status : null
}

output "jira_instance_id" {
  description = "ID of the Jira EC2 instance"
  value       = aws_instance.jira.id
}

output "jira_private_ip" {
  description = "Private IP of the Jira EC2 instance"
  value       = aws_instance.jira.private_ip
}

output "rds_endpoint" {
  description = "Endpoint of the RDS PostgreSQL instance"
  value       = aws_db_instance.jira.endpoint
}

output "rds_database_name" {
  description = "Name of the Jira database"
  value       = aws_db_instance.jira.db_name
}

output "ssm_connect_command" {
  description = "Command to connect to Jira instance via SSM"
  value       = "aws ssm start-session --target ${aws_instance.jira.id}"
}
