# Output the public IP of the EC2 instance
output "instance_public_ip" {
  value = aws_instance.my_ec2.public_ip
}
