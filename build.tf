terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "us-east-1"
}

# 1. Custom VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "url-shortener-vpc"
    Environment = "production"
  }
}

# 2. Internet Gateway (for future Public Subnets & ALB)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "url-shortener-igw"
  }
}

resource "aws_subnet" "Public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "url-shortener-public_Subnet_1"
  }
}

resource "aws_subnet" "Public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "url-shortener-public_Subnet_2"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "url-shortener-private_Subnet_1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "url-shortener-private_Subnet_2"
  }
}


# 2. Public Route Table (The Map to the Internet)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "url-shortener-public_Subnet_rt"
  }
}

# 3. Route Table Associations (Taping the Map to Public Rooms)
resource "aws_route_table_association" "Public_1" {
  subnet_id      = aws_subnet.Public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "Public_2" {
  subnet_id      = aws_subnet.Public_2.id
  route_table_id = aws_route_table.public.id
}



