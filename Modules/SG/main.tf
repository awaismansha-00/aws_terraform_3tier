// ------------------------ Security Group for External Load Balancer ------------------------
resource "aws_security_group" "external_alb_sg" {
  name = "${var.environment}-${var.project}-external-alb-sg"
  description = "Security group for External Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP traffic from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// ------------------------ Security Group for Internal Load Balancer ------------------------
resource "aws_security_group" "internal_alb_sg" {
  name = "${var.environment}-${var.project}-internal-alb-sg"
  description = "Security group for Internal Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTP traffic from frontend security group"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
  
// ------------------------ Security Group for DB ------------------------
resource "aws_security_group" "db_sg" {
  name = "${var.environment}-${var.project}-db-sg"
  description = "Security group for DB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow PostgreSQL traffic from backend security group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// ------------------------ Security Group for Frontend ------------------------
resource "aws_security_group" "frontend_sg" {
  name = "${var.environment}-${var.project}-frontend-sg"
  description = "Security group for Frontend"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTP traffic from Frontend Load Balancer Security Group"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.external_alb_sg.id]

  }

  ingress {
    description     = "Allow SSH traffic from Bastion Host Security Group"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_host_sg.id]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// ------------------------ Security Group for Backend ------------------------
resource "aws_security_group" "backend_sg" {
  name = "${var.environment}-${var.project}-backend-sg"
  description = "Security group for Backend"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb_sg.id]

  }

  ingress {
    description     = "Allow SSH traffic from Bastion Host Security Group"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_host_sg.id]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


// ------------------------ Security Group for Bastion Host ------------------------
resource "aws_security_group" "bastion_host_sg" {
  name = "${var.environment}-${var.project}-bastion-host-sg"
  description = "Security group for Bastion Host"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH traffic from allowed IPs"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = var.allowed_IPs

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
