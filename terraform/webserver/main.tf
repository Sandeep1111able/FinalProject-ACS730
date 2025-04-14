terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.27"
    }
  }
  required_version = ">= 0.14"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# Load outputs from network state
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "acs730-finalproject"
    key    = "prod/network/terraform.tfstate"
    region = "us-east-1"
  }
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Local tagging helpers
locals {
  default_tags = merge(var.default_tags, { "env" = var.env })
  name_prefix  = "${var.prefix}-${var.env}"
}

# SSH Key
resource "aws_key_pair" "prod_key" {
  key_name   = var.prefix
  public_key = file("${var.prefix}.pub")
}

# Public SG for Web + Bastion
resource "aws_security_group" "public" {
  name   = "${var.prefix}-public-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${var.prefix}-public-sg" })
}

# Private SG for DB and VM6
resource "aws_security_group" "private" {
  name   = "${var.prefix}-private-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${var.prefix}-private-sg" })
}

# Webservers (Web1, Web3, Web4) + Bastion (Web2)
resource "aws_instance" "web" {
  count         = 4
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.prod_key.key_name
  subnet_id     = element(data.terraform_remote_state.network.outputs.public_subnet_ids, count.index)
  vpc_security_group_ids = [aws_security_group.public.id]
  associate_public_ip_address = true
  user_data     = file("${path.module}/install_httpd.sh")

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-web-${count.index + 1}"
    Role = count.index == 1 ? "Bastion" : "Web"
  })
}


# DB Server (Private Subnet 1)
resource "aws_instance" "db" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.prod_key.key_name
  subnet_id              = data.terraform_remote_state.network.outputs.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.private.id]
  user_data              = file("${path.module}/install_db.sh")

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-db"
    Role = "Database"
  })
}

# VM6 (Private Subnet 2)
resource "aws_instance" "vm6" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.prod_key.key_name
  subnet_id              = data.terraform_remote_state.network.outputs.private_subnet_ids[1]
  vpc_security_group_ids = [aws_security_group.private.id]

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-vm6"
    Role = "Internal-VM"
  })
}

# Application Load Balancer
resource "aws_lb" "web_alb" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.terraform_remote_state.network.outputs.public_subnet_ids
  security_groups    = [aws_security_group.public.id]

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-alb"
  })
}

# Target Group
resource "aws_lb_target_group" "web_tg" {
  name     = "${local.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-tg"
  })
}

# Attach all 4 webservers to ALB
resource "aws_lb_target_group_attachment" "web_targets" {
  count            = 3  
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

# Listener
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

