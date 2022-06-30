# Output the public DNS of Loadbalancer
output "web-server-lb-public-dns" {
    value = module.myapp-webserver.public-lb.dns_name
}

# Output the public IP of EC2 server
output "web-server-public-ip" {
    value = module.myapp-webserver.webserver-ec2.public_ip
}

# Output the endpoint of RDS instance
output "rds_dns" {
    value = module.myapp-database.mysql-rds.endpoint
}