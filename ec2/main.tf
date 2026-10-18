
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

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get the default security group
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Create server and monitoring EC2 instances
resource "aws_instance" "instances" {
  for_each = toset(["server", "monitoring"])

  ami           = "ami-01a00762f46d584a1"
  instance_type = "c7i-flex.large"

  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [
    data.aws_security_group.default.id
  ]

  key_name = "key"

  root_block_device {
    volume_size = 25
    volume_type = "gp3"
  }

  tags = {
    Name        = each.value
    Environment = "DevOps"
  }
}

# Display instance details
output "instance_details" {
  value = {
    for name, instance in aws_instance.instances : name => {
      id         = instance.id
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
    }
  }
}
