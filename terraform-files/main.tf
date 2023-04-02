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


resource "aws_instance" "nodes" {
  ami = element(var.myami, count.index)
  instance_type = var.instancetype
  count = var.num
  key_name = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-sec-gr.id]
  tags = {
    Name = "${element(var.tags, count.index)}"
  }
}

resource "aws_security_group" "tf-sec-gr" {
  name = "erkut-project-sec-gr"
  tags = {
    Name = "erkut-project-sec-gr"
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
    host = aws_instance.nodes[0].public_ip
    type = "ssh"
    user = "ec2-user"
    private_key = file("~/.ssh/${var.mykey}.pem")
    
  }

  provisioner "file" {
    source = "./ansible.cfg"
    destination = "/home/ec2-user/ansible.cfg"
  }

  provisioner "file" {
    # Do not forget to define your key file path correctly!
    source = "~/.ssh/${var.mykey}.pem"
    destination = "/home/ec2-user/${var.mykey}.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname Control-Node",
      "sudo yum update -y",
      "sudo amazon-linux-extras install ansible2 -y",
      "echo [allservers] >> inventory.txt",
      "echo Ks8 ansible_host=${aws_instance.nodes[1].private_ip} ansible_ssh_private_key_file=~/${var.mykey}.pem ansible_user=ubuntu >> inventory.txt",
      "echo CI/CD ansible_host=${aws_instance.nodes[2].private_ip} ansible_ssh_private_key_file=~/${var.mykey}.pem ansible_user=ubuntu >> inventory.txt",
      "echo [Ks8-Server] >> inventory.txt",
      "echo Ks8 ansible_host=${aws_instance.nodes[1].private_ip} ansible_ssh_private_key_file=~/${var.mykey}.pem ansible_user=ubuntu >> inventory.txt",
      "echo [CI/CD-Server] >> inventory.txt",
      "echo CI/CD ansible_host=${aws_instance.nodes[2].private_ip} ansible_ssh_private_key_file=~/${var.mykey}.pem ansible_user=ubuntu >> inventory.txt",
      "chmod 400 ${var.mykey}.pem"
    ]
  }
}

output "Config-Server" {
  value = aws_instance.nodes[0].public_ip
}