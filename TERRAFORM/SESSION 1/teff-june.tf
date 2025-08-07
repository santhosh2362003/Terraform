terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "MY-VPC"
  }
}

resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone ="eu-west-2a"

  tags = {
    Name = "My-Public-subnet"
  }
}

resource "aws_subnet" "prisub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone ="eu-west-2c"

  tags = {
    Name = "My-Private-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "My-IGW"
  }
}

resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

   tags = {
    Name = "My-public-RT"
  }
}

resource "aws_route_table_association" "pubsubasso" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrt.id
}

resource "aws_eip" "myeip" {
  vpc   = true
}

resource "aws_nat_gateway" "mynat" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "My-Nat-gateway"
  }
}

  resource "aws_route_table" "prirt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.mynat.id
  }

   tags = {
    Name = "My-Private-RT"
  }
}

resource "aws_route_table_association" "prisubasso" {
  subnet_id      = aws_subnet.prisub.id
  route_table_id = aws_route_table.prirt.id
}

resource "aws_security_group" "pubsg" {
  name        = "pub-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "PUB-SG"
  }
}

resource "aws_security_group" "prisg" {
  name        = "pri-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
}

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "PRI-SG"
  }
}

resource "aws_instance" "pub_instance" {
  ami                                             = "ami-0bc8d5c547360e648"
  instance_type                                   = "t2.micro"
  availability_zone                               = "eu-west-2a"
  associate_public_ip_address                     = "true"
  vpc_security_group_ids                          = [aws_security_group.pubsg.id]
  subnet_id                                       = aws_subnet.pubsub.id 
  key_name                                        = "teff-june"
  
    tags = {
    Name = "Public-Server"
  }
}

resource "aws_instance" "pri_instance" {
  ami                                             = "ami-0bc8d5c547360e648"
  instance_type                                   = "t2.micro"
  availability_zone                               = "eu-west-2c"
  associate_public_ip_address                     = "false"
  vpc_security_group_ids                          = [aws_security_group.prisg.id]
  subnet_id                                       = aws_subnet.prisub.id 
  key_name                                        = "teff-june"
  
    tags = {
    Name = "Private-Server"
  }
}






