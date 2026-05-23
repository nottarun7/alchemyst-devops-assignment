terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# =========================
# VPC
# =========================

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "alchemyst-vpc"
  }
}

# =========================
# PUBLIC SUBNET
# =========================

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# =========================
# PRIVATE SUBNET
# =========================

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private-subnet"
  }
}

# =========================
# INTERNET GATEWAY
# =========================

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# =========================
# PUBLIC ROUTE TABLE
# =========================

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# =========================
# ROUTE TABLE ASSOCIATION
# =========================

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# =========================
# SECURITY GROUP
# =========================

resource "aws_security_group" "main_sg" {
  name   = "alchemyst-sg"
  vpc_id = aws_vpc.main.id

  # SSH access

  ingress {
    description = "SSH"

    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  # REST API

  ingress {
    description = "REST API"

    from_port = 3111
    to_port   = 3111
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  # Stream API

  ingress {
    description = "Stream API"

    from_port = 3112
    to_port   = 3112
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  # Internal iii worker communication

  ingress {
    description = "Internal VPC Communication"

    from_port = 49134
    to_port   = 49134
    protocol  = "tcp"

    cidr_blocks = ["10.0.0.0/16"]
  }

  # Outbound traffic

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alchemyst-security-group"
  }
}

# =========================
# API VM (PUBLIC)
# =========================

resource "aws_instance" "api_vm" {

  ami           = "ami-0f58b397bc5c1f2e8"
  instance_type = "t3.small"

  subnet_id = aws_subnet.public_subnet.id

  vpc_security_group_ids = [
    aws_security_group.main_sg.id
  ]

  key_name = "alchemyst-key"

  tags = {
    Name = "api-vm"
  }
}

# =========================
# INFERENCE VM (PRIVATE)
# =========================

resource "aws_instance" "inference_vm" {

  ami           = "ami-0f58b397bc5c1f2e8"
  instance_type = "t3.small"

  subnet_id = aws_subnet.public_subnet.id

  associate_public_ip_address = true
  
  vpc_security_group_ids = [
    aws_security_group.main_sg.id
  ]

  key_name = "alchemyst-key"

  tags = {
    Name = "inference-vm"
  }
}