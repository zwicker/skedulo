provider "aws" {
  access_key = "${var.AWS_ACCESS_KEY}"
  secret_key = "${var.AWS_SECRET_KEY}"
  region     = "ap-southeast-2"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "production_docker" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "production_docker" {
  vpc_id = "${aws_vpc.production_docker.id}"
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "production_webservers" {
  name        = "production_webservers"
  description = "Used in generating skedulo webservices"
  vpc_id      = "${aws_vpc.production_docker.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.production_docker.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.production_docker.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "production_docker" {
  vpc_id                  = "${aws_vpc.production_docker.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}


resource "aws_instance" "Web_server_1" {
  ami           = "ami-4e686b2d"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.production_docker.id}"
  key_name      = "${var.keyname}"
  vpc_security_group_ids = ["${aws_security_group.production_webservers.id}"]
  tags {
    Name = "Production Webserver #1"
  }
  private_ip = "10.0.1.31"
  connection {
        type = "ssh"
        user = "ubuntu"
        private_key = "${file(var.keyfile)}"
        timeout = "2m"
        agent = false
    }
  provisioner "remote-exec" {
        inline = [
        "sudo apt-get update",
        "sudo apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual",
        "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
        "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add",
        "sudo add-apt-repository deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable",
        "sudo apt-get update",
        "sudo apt-get -y install docker.io",
        "sudo docker run -d -p 3000:3000 --name node-app zwicker/node-app",
        "sudo docker run -it -d -p 8080:8080 --name golang-app zwicker/go-app"
        ]
    }
}

resource "aws_instance" "Web_server_2" {
  ami           = "ami-4e686b2d"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.production_docker.id}"
  key_name      = "${var.keyname}"
  vpc_security_group_ids = ["${aws_security_group.production_webservers.id}"]
  tags {
    Name = "Production Webserver #2"
  }
  private_ip = "10.0.1.32"
  connection {
        type = "ssh"
        user = "ubuntu"
        private_key = "${file(var.keyfile)}"
        timeout = "2m"
        agent = false
    }
  provisioner "remote-exec" {
        inline = [
        "sudo apt-get update",
        "sudo apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual",
        "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
        "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add",
        "sudo add-apt-repository deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable",
        "sudo apt-get update",
        "sudo apt-get -y install docker.io",
        "sudo docker run -d -p 3000:3000 --name node-app zwicker/node-app",
        "sudo docker run -it -d -p 8080:8080 --name golang-app zwicker/go-app"
        ]
    }
}

resource "aws_instance" "load_balancer" {
  ami           = "ami-4e686b2d"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.production_docker.id}"
  key_name      = "${var.keyname}"
  vpc_security_group_ids = ["${aws_security_group.production_webservers.id}"]
  tags {
    Name = "load_balancer"
  }
  private_ip = "10.0.1.33"
  connection {
        type = "ssh"
        user = "ubuntu"
        private_key = "${file(var.keyfile)}"
        timeout = "2m"
        agent = false
    }
  provisioner "remote-exec" {
        inline = [
        "sudo apt-get update",
        "sudo apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual",
        "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
        "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add",
        "sudo add-apt-repository deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable",
        "sudo apt-get update",
        "sudo apt-get -y install docker.io",
        "sudo docker run -it -d -p 80:80 --name haproxy zwicker/haproxy"
        ]
    }
}

output "ip" {
    value = "Please connect to - http://${aws_instance.load_balancer.public_ip}/go/ or http://${aws_instance.load_balancer.public_ip}/js/"
}
