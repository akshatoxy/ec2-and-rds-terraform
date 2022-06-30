# Create a VPC
resource "aws_vpc" "dev-vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "dev-vpc"
    }
}

# Create an internet gateway to connect to the internet
resource "aws_internet_gateway" "dev-igw" {
    vpc_id = aws_vpc.dev-vpc.id

    tags = {
        Name = "dev-igw"
    }
}

# Create a route table for web server
resource "aws_route_table" "dev-rt" {
    vpc_id = aws_vpc.dev-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.dev-igw.id
    }

    tags = {
        Name = "dev-rt"
    }
}

# Create a public subnet for the web server
resource "aws_subnet" "dev-public-subnet-1" {
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = var.public_subnet_1_cidr
    availability_zone = var.public_subnet_1_az
    map_public_ip_on_launch = true


    tags = {
        Name = "dev-public-subnet-1"
    }
}

# Create a 2nd public subnet for the web server
resource "aws_subnet" "dev-public-subnet-2" {
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = var.public_subnet_2_cidr
    availability_zone = var.public_subnet_2_az
    map_public_ip_on_launch = true

    tags = {
        Name = "dev-public-subnet-2"
    }
}

# Create a private subnet for the mysql server
resource "aws_subnet" "dev-private-subnet-1" {
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = var.private_subnet_1_cidr
    availability_zone = var.private_subnet_1_az

    tags = {
        Name = "dev-private-subnet-1"
    }
}

# Create a 2nd private subnet for the mysql server
resource "aws_subnet" "dev-private-subnet-2" {
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = var.private_subnet_2_cidr
    availability_zone = var.private_subnet_2_az

    tags = {
        Name = "dev-private-subnet-2"
    }
}

# Create route table associations for our subnets
resource "aws_route_table_association" "dev-rta-1" {
  subnet_id = aws_subnet.dev-public-subnet-1.id
  route_table_id = aws_route_table.dev-rt.id
}

resource "aws_route_table_association" "dev-rta-2" {
  subnet_id = aws_subnet.dev-public-subnet-2.id
  route_table_id = aws_route_table.dev-rt.id
}

resource "aws_route_table_association" "dev-rta-3" {
  subnet_id = aws_subnet.dev-private-subnet-1.id
  route_table_id = aws_route_table.dev-rt.id
}

resource "aws_route_table_association" "dev-rta-4" {
  subnet_id = aws_subnet.dev-private-subnet-2.id
  route_table_id = aws_route_table.dev-rt.id
}