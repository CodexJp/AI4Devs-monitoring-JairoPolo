# Unified Security Group para instancia monorepo con Datadog
resource "aws_security_group" "unified_sg" {
  name_prefix = "ai4devs-unified-"
  description = "Unified security group for monorepo instance with Datadog monitoring"

  # SSH Access para management
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Backend API (Node.js/Express)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Backend API"
  }

  # Frontend Web (React)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Frontend web interface"
  }

  # PostgreSQL Database (for external management if needed)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
    description = "PostgreSQL database access from private networks"
  }

  # HTTPS Egress (Datadog, NPM, Docker Hub, etc.)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS egress for Datadog, NPM, Docker Hub"
  }

  # HTTP Egress para system updates
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP egress for system updates"
  }

  # DNS Resolution
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS resolution"
  }

  # All internal Docker network communication
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/12"]
    description = "Internal Docker network communication"
  }

  tags = {
    Name        = "ai4devs-unified-sg"
    Environment = "production"
    Service     = "monorepo-instance"
    Monitoring  = "datadog"
  }
}