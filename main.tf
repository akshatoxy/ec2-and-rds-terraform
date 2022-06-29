provider "aws" {
    region = "us-east-1"
}

variable "vpc_cidr" {}
variable "public_subnet_1_cidr" {}
variable "public_subnet_1_az" {}
variable "public_subnet_2_cidr" {}
variable "public_subnet_2_az" {}
variable "private_subnet_1_cidr" {}
variable "private_subnet_1_az" {}
variable "private_subnet_2_cidr" {}
variable "private_subnet_2_az" {}
variable "web_server_key" {}

data "aws_ami" "amazon-linux-2" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name   = "name"
        values = ["amzn2-ami-kernel-5.10-hvm-2.0.20220606.1-x86_64-gp2"]
    }
}
   
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

# Create a security group for the web server
resource "aws_security_group" "web-server-sg" {
    vpc_id = aws_vpc.dev-vpc.id

    ingress {
        description = "HTTP request for web server"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = [ "0.0.0.0/0" ]
    }

    tags = {
        Name = "web-server-sg"
    }
}

# Create a Key pair for web server
resource "aws_key_pair" "web-server-key" {
    key_name = "web-server-key"
    public_key = var.web_server_key
}   

# Create an EC2 instance
resource "aws_instance" "web-server-ec2" {
    ami = data.aws_ami.amazon-linux-2.id
    instance_type = "t2.micro"
    associate_public_ip_address = true
    subnet_id = aws_subnet.dev-public-subnet-1.id
    vpc_security_group_ids = [ aws_security_group.web-server-sg.id ]
    key_name = aws_key_pair.web-server-key.key_name

    tags = {
        Name = "web-server-ec2"
    }
}

# Create an ELB for the EC2 instances
resource "aws_lb" "web-server-lb" {
    name = "web-server-lb"
    internal = false
    load_balancer_type = "application"
    security_groups = [ aws_security_group.web-server-sg.id ]
    subnets = [ aws_subnet.dev-public-subnet-1.id, aws_subnet.dev-public-subnet-2.id ]
}

resource "aws_lb_target_group" "web-server-tg" {
    name = "web-server-tg"
    port = "8080"
    protocol = "HTTP"
    vpc_id = aws_vpc.dev-vpc.id
}

resource "aws_lb_target_group_attachment" "web-server-tga" {
    target_group_arn = aws_lb_target_group.web-server-tg.arn
    target_id = aws_instance.web-server-ec2.id
    port = "8080" 
}

resource "aws_lb_listener" "web-server-lb-listener" {
    load_balancer_arn = aws_lb.web-server-lb.arn
    port = "8080"
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.web-server-tg.arn
    }
}

resource "aws_db_subnet_group" "rds-private-subnet" {
    subnet_ids = [ aws_subnet.dev-private-subnet-1.id, aws_subnet.dev-private-subnet-2.id ]

    tags = {
        Name = "my-rds-private-subnet-group"
    }
}

resource "aws_security_group" "rds-sg" {
    vpc_id = aws_vpc.dev-vpc.id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = [ "10.0.0.0/16" ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    tags = {
        Name = "my-rds-sg"
    }
}

resource "aws_db_instance" "my-rds-sql" {
    allocated_storage = 20
    storage_type = "gp2"
    engine = "mysql"
    engine_version = "5.7"
    instance_class = "db.t2.micro"
    username = "root"
    password = "12345678"
    parameter_group_name = "default.mysql5.7"
    db_subnet_group_name = aws_db_subnet_group.rds-private-subnet.name
    vpc_security_group_ids = [ aws_security_group.rds-sg.id ]
    multi_az = false
    db_name = "testdb"
    backup_retention_period = 35
    skip_final_snapshot = true
}

# Output the public DNS of Loadbalancer
output "web-server-lb-public-dns" {
    value = aws_lb.web-server-lb.dns_name
}

output "web-server-public-ip" {
    value = aws_instance.web-server-ec2.public_ip
}

output "rds_dns" {
    value = aws_db_instance.my-rds-sql.endpoint
}