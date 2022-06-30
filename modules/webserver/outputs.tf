output "public-lb" {
    value = aws_lb.web-server-lb
}

output "webserver-ec2" {
    value = aws_instance.web-server-ec2
}