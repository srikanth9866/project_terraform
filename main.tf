resource "aws_instance" "my_ec2" {
  ami           = "ami-05fa46471b02db0ce"  # Update with the latest AMI ID for Mumbai
  instance_type = "t2.medium"
  subnet_id     = data.aws_subnet.default.id
  key_name      = "mum-sri"  # Use your existing key pair

  vpc_security_group_ids = [
    length(data.aws_security_group.existing_terraform_sg.id) == 0 ? 
    aws_security_group.terraform_sg[0].id : 
    data.aws_security_group.existing_terraform_sg.id
  ]

  associate_public_ip_address = true

  tags = {
    Name = "MyEC2Instance"
  }

  provisioner "file" {
    source      = "install.sh"
    destination = "/home/ec2-user/install.sh"
  }

  provisioner "file" {
    source      = "Dockerfile"
    destination = "/home/ec2-user/Dockerfile"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/install.sh",
      "sudo /home/ec2-user/install.sh"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("/root/mumbai-sri.pem")  # Correct path to the PEM file on Jenkins server
    host        = self.public_ip
  }
}
