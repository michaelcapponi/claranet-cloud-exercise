/*
* ## Description
*
* **Version**: 2.0
* Terraform network resources 
* Terraform added application (alb + asg) and db resources
*/

terraform {
  required_version = "~> 1.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 4.49"
    }
  }
  backend "s3" {
    bucket  = "tf-state-phoenix-app"
    key     = "app/terraform.tfstate"
    region  = "eu-central-1"
  }
}

locals {
  azs = [ "eu-central-1a", "eu-central-1b", "eu-central-1c"]
}


provider "aws" {
  region = var.region
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "phoenix-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  count = 3
  cidr_block = "10.0.${count.index}.0/24"
  vpc_id     = aws_vpc.vpc.id
  availability_zone = local.azs[count.index]
  tags = {
    Name = "phoenix-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  count = 3

  cidr_block = "10.0.${count.index + 3}.0/24" #+3 to shift ip cidr block from public subnets 
  vpc_id     = aws_vpc.vpc.id
  availability_zone = local.azs[count.index]
  tags = {
    Name = "phoenix-private-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "phoenix-igw"
  }
}

# need EIP to create a NAT Gateway
resource "aws_eip" "eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "phoenix-nat"
  }
}

#add to public route table a route to the igw id and to private a route to the nat id
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "phoenix-public-rt"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "phoenix-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = 3
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private" {
  count = 3

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}


