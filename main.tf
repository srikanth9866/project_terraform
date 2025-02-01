provider "aws" {
  region = "ap-south-1"  # Mumbai region
}

terraform {
  backend "s3" {
    bucket = "sri39280319991"   # Your S3 bucket for storing Terraform state
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}

# Fetch the Default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch the Default Public Subnet in Mumbai Region
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Select the first available subnet
data "aws_subnet" "default" {
  id = tolist(data.aws_subnets.default.ids)[0]
}

# Check if the "terraform" Security Group exists
data "aws_security_group" "existing_terraform_sg" {
  filter {
    name   = "group-name"
    values = ["terraform"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create Security Group only if "terraform" SG does not exist
resource "aws_security_group" "terraform_sg" {
  count       = length(data.aws_security_group.existing_terraform_sg.id) == 0 ? 1 : 0
  name        = "terraform"
  description = "Terraform-managed security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22  # SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80  # HTTP
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443  # HTTPS
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TerraformSecurityGroup"
  }
}

# Create an EC2 Instance
resource "aws_instance" "my_ec2" {
  ami           = "ami-05fa46471b02db0ce" # Update with the latest AMI ID for Mumbai
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
    private_key = file("/var/lib/jenkins/mumbai-sri.pem")  # Path on the Jenkins server
    host        = self.public_ip
  }
}
