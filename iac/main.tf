# main.tf
# -----------------------------------------------
# CloudTopia Environment - Infrastructure as Code
# -----------------------------------------------
# This Terraform file describes a small AWS environment
# with one VPC, one subnet, one security group, and one EC2 instance.
# I created this same setup manually in the AWS console.

# 1. Provider: tells Terraform to use AWS
provider "aws" {
  region = "us-east-1"  # You can change this if your sandbox uses another region
}

# 2. Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "cloudtopia_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "cloudtopia-vpc"
  }
}

# 3. Create a subnet inside the VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = my-test-VPC2658.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "cloudtopia-public-subnet"
  }
}

# 4. Internet Gateway for public internet access
resource "aws_internet_gateway" "igw" {
  vpc_id = my-test-VPC2658.id
  tags = {
    Name = "cloudtopia-igw"
  }
}

# 5. Route Table to connect the subnet to the Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.cloudtopia_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "cloudtopia-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 6. Security Group to allow web traffic (port 80)
resource "aws_security_group" "web_sg" {
  name        = "cloudtopia-web-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.cloudtopia_vpc.id

  ingress {
    description = "HTTP from anywhere"
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

  tags = {
    Name = "cloudtopia-web-sg"
  }
}

# 7. Virtual Machine (EC2 instance)
resource "aws_instance" "web_server" {
  ami           = "ami-08c40ec9ead489470"  # Amazon Linux 2 AMI for us-east-1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  # User data: setup simple web server
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl enable httpd
              sudo systemctl start httpd
              echo "<h1>Welcome to CloudTopia Web Server</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "cloudtopia-web-instance"
  }
}
