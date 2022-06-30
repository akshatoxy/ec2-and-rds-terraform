# Fetch ami of Amazon Linux 2
data "aws_ami" "amazon-linux-2" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name   = "name"
        values = [ var.ami_name ]
    }
}

# Create a security group for the web server
resource "aws_security_group" "web-server-sg" {
    vpc_id = var.vpc_id

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
    subnet_id = var.public_subnet_1_id
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
    subnets = [ var.public_subnet_1_id, var.public_subnet_2_id ]
}

# Create Target group for the ELB
resource "aws_lb_target_group" "web-server-tg" {
    name = "web-server-tg"
    port = "8080"
    protocol = "HTTP"
    vpc_id = var.vpc_id
}

# Create attachment for the EC2 server
resource "aws_lb_target_group_attachment" "web-server-tga" {
    target_group_arn = aws_lb_target_group.web-server-tg.arn
    target_id = aws_instance.web-server-ec2.id
    port = "8080" 
}

# Create a listener for the ELB
resource "aws_lb_listener" "web-server-lb-listener" {
    load_balancer_arn = aws_lb.web-server-lb.arn
    port = "8080"
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.web-server-tg.arn
    }
}