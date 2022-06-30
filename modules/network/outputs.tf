output "vpc" {
    value = aws_vpc.dev-vpc
}

output "public-subnet-1" {
    value = aws_subnet.dev-public-subnet-1
}

output "public-subnet-2" {
    value = aws_subnet.dev-public-subnet-2
}

output "private-subnet-1" {
    value = aws_subnet.dev-private-subnet-1
}

output "private-subnet-2" {
    value = aws_subnet.dev-private-subnet-2
}

