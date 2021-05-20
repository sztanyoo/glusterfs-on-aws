variable "instance_count" {
  default = "3"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_instance" "glusternode" {
  count         = "${var.instance_count}"
  ami           = "ami-00e87074e52e6c9f9"
  instance_type = "t3.micro"
  key_name = "glusterec2user"
  security_groups = [ "allow_all", "allow_outgoing" ]


  tags = {
    Name = "gluster${count.index +1}"
    Role = "glusternode"
  }
}

resource "aws_key_pair" "glusterec2user" {
  key_name   = "glusterec2user"
  public_key = file("id_rsa_glusterroot.pub")
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    description      = "SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

# TODO: restrict from peer vpc

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow Gluster inbound traffic"
  ingress {
    description      = "NFS from everywhere"
    from_port        = 1
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_all"
  }
}

resource "aws_security_group" "allow_gluster" {
  name        = "allow_gluster"
  description = "Allow Gluster inbound traffic"

  ingress {
    description      = "Gluster from everywhere"
    from_port        = 24007
    to_port          = 24009
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "NFS from everywhere 111"
    from_port        = 111
    to_port          = 111
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "NFS from everywhere 2049"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "NFS from everywhere udp111"
    from_port        = 111
    to_port          = 111
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "NFS from everywhere udp2049"
    from_port        = 2049
    to_port          = 2049
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_security_group" "allow_outgoing" {
  name        = "allow_outgoing"
  description = "Allow outbound traffic"

   egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_outgoing"
  }
}

data "template_file" "sshconfig" {
  template = "${file("localsshconfig.tpl")}"
  count = "${var.instance_count}"
  vars = {
    address = "${aws_instance.glusternode[count.index].public_ip}"
    name = "${aws_instance.glusternode[count.index].tags["Name"]}"
  }
}

resource "local_file" "gluster_ssh_config" {
  content = "${join("\n",data.template_file.sshconfig.*.rendered)}"
  filename = "gluster_ssh_config"
}


data "template_file" "ansible_inventory" {
  template = "${file("gluster_inventory.tpl")}"
  count = "${var.instance_count}"
  vars = {
    host = "${aws_instance.glusternode[count.index].tags["Name"]}"
    public_ip = "${aws_instance.glusternode[count.index].public_ip}"
    ipv4_dns = "${aws_instance.glusternode[count.index].public_dns}"
  }
}

resource "local_file" "ansible_inventory" {
  content = "gluster_members:\n  vars:\n\n  hosts:\n${join("\n",data.template_file.ansible_inventory.*.rendered)}"
  filename = "gluster_inventory"
}


