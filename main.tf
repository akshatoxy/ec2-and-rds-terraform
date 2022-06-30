provider "aws" {
    region = "us-east-1"
}

# Module for the network
module "myapp-network" {
    source = "./modules/network"
    vpc_cidr = var.vpc_cidr
    public_subnet_1_cidr = var.public_subnet_1_cidr
    public_subnet_1_az = var.public_subnet_1_az
    public_subnet_2_cidr = var.public_subnet_2_cidr
    public_subnet_2_az = var.public_subnet_2_az
    private_subnet_1_cidr = var.private_subnet_1_cidr
    private_subnet_1_az = var.private_subnet_1_az
    private_subnet_2_cidr = var.private_subnet_2_cidr
    private_subnet_2_az = var.private_subnet_2_az
}

# Module for the web server
module "myapp-webserver" {
    source = "./modules/webserver"
    ami_name = var.ami_name
    vpc_id = module.myapp-network.vpc.id
    web_server_key = var.web_server_key
    public_subnet_1_id = module.myapp-network.public-subnet-1.id
    public_subnet_2_id = module.myapp-network.public-subnet-2.id
}

# Module for RDS MySQL instance
module "myapp-database" {
    source = "./modules/database"
    private_subnet_1_id = module.myapp-network.private-subnet-1.id
    private_subnet_2_id = module.myapp-network.private-subnet-2.id
    vpc_id = module.myapp-network.vpc.id
}
