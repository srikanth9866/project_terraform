#!/bin/bash

# Install Java 17
sudo dnf install java-17-amazon-corretto -y

# Install Maven (default version)
sudo dnf install maven -y

# Install Docker
sudo yum install docker -y

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to the docker group
sudo usermod -aG docker ec2-user

# Restart Docker
sudo systemctl restart docker

# Adjust Docker socket permissions
sudo chmod 666 /var/run/docker.sock

# Verify Docker installation
docker --version