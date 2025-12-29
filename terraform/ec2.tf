# IAM Role for EC2
resource "aws_iam_role" "jira" {
  name = "${var.project_name}-${var.environment}-jira-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-jira-role"
  }
}

# IAM Policy for SSM and CloudWatch
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.jira.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.jira.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "jira" {
  name = "${var.project_name}-${var.environment}-jira-profile"
  role = aws_iam_role.jira.name
}

# User Data Script for Docker and Jira Setup
locals {
  github_raw_url = "https://raw.githubusercontent.com/${var.github_repo}/${var.github_branch}"

  user_data = <<-EOF
    #!/bin/bash
    set -ex

    # Update system
    dnf update -y

    # Install Docker
    dnf install -y docker
    systemctl enable docker
    systemctl start docker

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Create Jira directories
    mkdir -p /opt/jira/data
    mkdir -p /opt/jira/build
    chmod 777 /opt/jira/data

    # Download agent JAR from GitHub
    curl -L "${local.github_raw_url}/docker/atlassian-agent.jar" -o /opt/jira/build/atlassian-agent.jar

    # Create Dockerfile
    cat > /opt/jira/build/Dockerfile <<'DOCKERFILE'
    FROM atlassian/jira-software:${var.jira_version}

    USER root

    # Add agent file
    COPY atlassian-agent.jar /opt/atlassian/jira/

    # Add agent to env
    RUN echo 'export CATALINA_OPTS="-javaagent:/opt/atlassian/jira/atlassian-agent.jar $${CATALINA_OPTS}"' >> /opt/atlassian/jira/bin/setenv.sh

    USER jira
    DOCKERFILE

    # Build custom Jira image
    cd /opt/jira/build
    docker build -t jira-custom:${var.jira_version} .

    # Create Docker Compose file
    cat > /opt/jira/docker-compose.yml <<'DOCKER_COMPOSE'
    version: '3.8'
    services:
      jira:
        image: jira-custom:${var.jira_version}
        container_name: jira
        restart: unless-stopped
        ports:
          - "8080:8080"
        environment:
          - ATL_JDBC_URL=jdbc:postgresql://${aws_db_instance.jira.endpoint}/${var.db_name}
          - ATL_JDBC_USER=${var.db_username}
          - ATL_JDBC_PASSWORD=${var.db_password}
          - ATL_DB_DRIVER=org.postgresql.Driver
          - ATL_DB_TYPE=postgres72
          - JVM_MINIMUM_MEMORY=${var.jira_memory}
          - JVM_MAXIMUM_MEMORY=${var.jira_memory}
          - ATL_PROXY_NAME=${var.domain_name != "" ? var.domain_name : ""}
          - ATL_PROXY_PORT=${var.domain_name != "" && var.route53_zone_id != "" ? "443" : "80"}
          - ATL_TOMCAT_SCHEME=${var.domain_name != "" && var.route53_zone_id != "" ? "https" : "http"}
          - ATL_TOMCAT_SECURE=${var.domain_name != "" && var.route53_zone_id != "" ? "true" : "false"}
        volumes:
          - /opt/jira/data:/var/atlassian/application-data/jira
        logging:
          driver: "json-file"
          options:
            max-size: "10m"
            max-file: "5"
    DOCKER_COMPOSE

    # Start Jira
    cd /opt/jira
    docker-compose up -d

    # Install CloudWatch agent
    dnf install -y amazon-cloudwatch-agent

    # Configure CloudWatch agent
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CLOUDWATCH'
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/opt/jira/data/log/atlassian-jira.log",
                "log_group_name": "/jira/${var.environment}/application",
                "log_stream_name": "{instance_id}",
                "retention_in_days": 30
              }
            ]
          }
        }
      },
      "metrics": {
        "namespace": "Jira/${var.environment}",
        "metrics_collected": {
          "cpu": {
            "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
            "totalcpu": true
          },
          "mem": {
            "measurement": ["mem_used_percent"]
          },
          "disk": {
            "measurement": ["disk_used_percent"],
            "resources": ["/"]
          }
        }
      }
    }
    CLOUDWATCH

    # Start CloudWatch agent
    systemctl enable amazon-cloudwatch-agent
    systemctl start amazon-cloudwatch-agent
  EOF
}

# EC2 Instance for Jira (in public subnet to avoid NAT Gateway cost)
resource "aws_instance" "jira" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.jira.id]
  iam_instance_profile   = aws_iam_instance_profile.jira.name
  key_name               = var.key_name != "" ? var.key_name : null

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_type           = "gp3"
    volume_size           = var.jira_data_volume_size
    encrypted             = true
    delete_on_termination = false
  }

  user_data = base64encode(local.user_data)

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-jira-server"
  }

  depends_on = [aws_db_instance.jira]
}
