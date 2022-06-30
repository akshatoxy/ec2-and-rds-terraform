# Create Subnet group for RDS instance
resource "aws_db_subnet_group" "rds-private-subnet" {
    subnet_ids = [ var.private_subnet_1_id, var.private_subnet_2_id ]

    tags = {
        Name = "my-rds-private-subnet-group"
    }
}

# Create Security group for RDS instance
resource "aws_security_group" "rds-sg" {
    vpc_id = var.vpc_id

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

# Create RDS MySQL instance
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