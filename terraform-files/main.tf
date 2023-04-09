//This Terraform Template creates 3 Ansible Machines on EC2 Instances
//Ansible Machines will run on AL-2023
//allowing SSH (22), HTTP (80) and 8080 connections from anywhere.
//User needs to select appropriate variables from "tfvars" file when launching the instance.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
  # secret_key = ""
  # access_key = ""
}

locals {
  user = "Erkut-Project"
}

resource "aws_instance" "nodes" {
  ami                    = var.myami
  instance_type          = var.instancetype
  count                  = var.num
  key_name               = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-sec-gr-linux.id]
  tags = {
    Name = "${element(var.tags, count.index)}-${local.user}"
  }
}

resource "aws_instance" "ubuntu_node" {
  ami                    = var.k8sami
  instance_type          = var.k8sinstancetype
  key_name               = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-sec-gr-ubuntu.id]
  tags = {
    Name = var.k8stags
  }
}

resource "aws_security_group" "tf-sec-gr-ubuntu" {
  name = "k8scluster-sec-gr-${local.user}"
  tags = {
    Name = "k8scluster-sec-gr-${local.user}"
  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  protocol = "tcp"
  from_port = 30000
  to_port = 32767
  cidr_blocks = ["0.0.0.0/0"]
}

  ingress {
    from_port   = 16443
    protocol    = "tcp"
    to_port     = 16443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10250
    protocol    = "tcp"
    to_port     = 10250
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10255
    protocol    = "tcp"
    to_port     = 10255
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 25000
    protocol    = "tcp"
    to_port     = 25000
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 12379
    protocol    = "tcp"
    to_port     = 12379
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 12257
    protocol    = "tcp"
    to_port     = 12257
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 12259
    protocol    = "tcp"
    to_port     = 12259
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 19001
    protocol    = "tcp"
    to_port     = 19001
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4789
    protocol    = "udp"
    to_port     = 4789
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "tf-sec-gr-linux" {
  name = "ansible-sec-gr-${local.user}"
  tags = {
    Name = "ansible-sec-gr-${local.user}"
  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    protocol    = "tcp"
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "null_resource" "config" {
  depends_on = [aws_instance.nodes[0]]
  connection {
    host        = aws_instance.nodes[0].public_ip
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/${var.mykey}.pem")
    
  }

  provisioner "file" {
    source      = "./ansible.cfg"
    destination = "/home/ec2-user/.ansible.cfg"
  }

  provisioner "file" {
    # Do not forget to define your key file path correctly!
    source      = "~/.ssh/${var.mykey}.pem"
    destination = "/home/ec2-user/${var.mykey}.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname Control-Node",
      "curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py",
      "python3 get-pip.py --user",
      "python3 -m pip install --user ansible",
      "echo [mynodes] >> inventory.txt",
      "echo node1 ansible_host=${aws_instance.nodes[1].private_ip} ansible_ssh_private_key_file=~/${var.mykey}.pem ansible_user=ec2-user >> inventory.txt",
      "echo node2 ansible_host=${aws_instance.ubuntu_node.private_ip} ansible_ssh_private_key_file=~/${var.mykey}.pem ansible_user=ubuntu >> inventory.txt",
      "chmod 400 ${var.mykey}.pem"
    ]
  }
}

output "controlnodeip" {
  value = aws_instance.nodes[0].public_ip
}