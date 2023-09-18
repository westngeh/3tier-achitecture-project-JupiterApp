terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" 
    }
  }
}

provider "aws" {
  region = "us-east-1"
}



resource "aws_vpc" "devpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "devpc"
    }
}
resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.devpc.id 
        tags = {
        Name = "Internet_gateway"
    }
    
  
}
## public subnets 
resource "aws_subnet" "public_subnetaz1" {
    vpc_id            = aws_vpc.devpc.id
    cidr_block        = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    tags = {
      Name = "public_subnetaz1"
    }
  
}
resource "aws_subnet" "public_subnetaz2" {
    vpc_id            = aws_vpc.devpc.id
    cidr_block        = "10.0.1.0/24"
    availability_zone = "us-east-1b"
    tags = {
      Name = "public_subnetaz2"
    }
  
}
## private app subnets 
resource "aws_subnet" "privateapp_subnetaz1" {
    vpc_id            = aws_vpc.devpc.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "us-east-1a"
    tags = {
      Name = "privateapp_subnetaz1"
    }
}
resource "aws_subnet" "privateapp_subnetaz2" {
    vpc_id            = aws_vpc.devpc.id
    cidr_block        = "10.0.3.0/24"
    availability_zone = "us-east-1b"
    tags = {
      Name = "privateapp_subnetaz2"
    }
}
## Private Data subnets 
resource "aws_subnet" "privatedata_subnetaz1" {
    vpc_id            = aws_vpc.devpc.id
    cidr_block        = "10.0.4.0/24"
    availability_zone = "us-east-1a"
    tags = {
      Name = "privatedata_subnetaz1"
    }
}
resource "aws_subnet" "privatedata_subnetaz2" {
    vpc_id            = aws_vpc.devpc.id
    cidr_block        = "10.0.5.0/24"
    availability_zone = "us-east-1b"
    tags = {
      Name = "privatedata_subnetaz2"
    }
}
resource "aws_eip" "eip1" {
  domain = "vpc"
 }
  resource "aws_eip" "eip2" {
  domain = "vpc"
}


resource "aws_nat_gateway" "Natgatewayaz1" {
    allocation_id = aws_eip.eip1.id
    subnet_id = aws_subnet.public_subnetaz1.id
    tags = {
      Name = "Natgatewayaz1"
    }
    depends_on = [aws_subnet.public_subnetaz1]
}
resource "aws_nat_gateway" "Natgatewayaz2" {
    allocation_id = aws_eip.eip2.id
    subnet_id = aws_subnet.public_subnetaz2.id
    tags = {
      Name = "Natgatewayaz2"
    }
    depends_on = [aws_subnet.public_subnetaz2]
}
## Route tables 
resource "aws_route_table" "publicRT" {
    vpc_id     = aws_vpc.devpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet_gateway.id

    } 

    tags = {
      Name = "publicRT"
    }
}
## private route tables 
resource "aws_route_table" "privateAppRT" {
    vpc_id     = aws_vpc.devpc.id

        route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.Natgatewayaz1.id

    }
    tags = {
      Name = "privateAppRT"
    }
  
}
resource "aws_route_table" "privateDataRT" {
    vpc_id     = aws_vpc.devpc.id

        route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.Natgatewayaz2.id

    }
    tags = {
      Name = "privateDataRT"
    }
}
##Public subnet association (frontend )
resource "aws_route_table_association" "public_subnetaz1" {
  subnet_id      = aws_subnet.public_subnetaz1.id
  route_table_id = aws_route_table.publicRT.id
}

resource "aws_route_table_association" "public_subnetaz2" {
  subnet_id      = aws_subnet.public_subnetaz2.id
  route_table_id = aws_route_table.publicRT.id
}
## Private subnet association AZ1
resource "aws_route_table_association" "privateApp_subnetaz1" {
  subnet_id      = aws_subnet.privateapp_subnetaz1.id
  route_table_id = aws_route_table.privateAppRT.id
}

resource "aws_route_table_association" "privatedata_subnetaz1" {
  subnet_id      = aws_subnet.privatedata_subnetaz1.id
  route_table_id = aws_route_table.privateAppRT.id
}
## Private subnet association AZ2
resource "aws_route_table_association" "privateApp_subnetAZ2" {
  subnet_id      = aws_subnet.privateapp_subnetaz2.id
  route_table_id = aws_route_table.privateDataRT.id
}

resource "aws_route_table_association" "privatedata_subnetaz2" {
  subnet_id      = aws_subnet.privatedata_subnetaz2.id
  route_table_id = aws_route_table.privateDataRT.id
}
## Security Groups 
# ALB security Group 
resource "aws_security_group" "alb_security_group" {
  name        = "alb_security_group"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.devpc.id

  # Allow incoming traffic on ports 80 and 443 from anywhere
  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_security_group"
  }
}

resource "aws_security_group" "webz" {
  name        = "webz"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.devpc.id

  # Allow incoming traffic from alb_security_group
  ingress {
    description     = "http access"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }
  ingress {
    description     = "https access"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webz"
  }
}
## deploying an EC2 instance in the private in the private subnet using webserver security Group 
resource "aws_instance" "app_server" {
  ami                    = "ami-0f67f2bce6006d762"
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.privateapp_subnetaz1.id
  vpc_security_group_ids = [aws_security_group.webz.id]
  tags = {
    Name = "app_server"
  }
 


  
}


