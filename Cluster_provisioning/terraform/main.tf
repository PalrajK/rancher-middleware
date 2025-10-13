provider "aws" {
  region = "us-east-1"
}

variable "key_name" {
  default = "rke2-key"
}

variable "ami_id" {
  default = "ami-0fc5d935ebf8bc3bc" # Ubuntu 22.04
}

variable "instance_type" {
  default = "t3.xlarge"
}

variable "my_ip_cidr" {
  default = "192.168.0.126/32"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "rke2-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "rke2-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "rke2-public-rt" }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "rke2-public-${count.index}" }
}

resource "aws_route_table_association" "public_assoc" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "rke2_sg" {
  name   = "rke2-cluster-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9345
    to_port     = 9345
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "rke2-cluster-sg" }
}

resource "tls_private_key" "rke2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "rke2" {
  key_name   = var.key_name
  public_key = tls_private_key.rke2.public_key_openssh
}

resource "aws_instance" "master" {
  count                       = 3
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[count.index].id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.rke2.key_name
  vpc_security_group_ids      = [aws_security_group.rke2_sg.id]
  tags                        = { Name = "rke2-master-${count.index}" }
}

resource "aws_instance" "worker" {
  count                       = 3
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[count.index].id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.rke2.key_name
  vpc_security_group_ids      = [aws_security_group.rke2_sg.id]
  tags                        = { Name = "rke2-worker-${count.index}" }
}

resource "aws_lb" "rke2" {
  name               = "rke2-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "masters" {
  name     = "rke2-masters"
  port     = 6443
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    protocol = "TCP"
    port     = "6443"
  }
}

resource "aws_lb_target_group" "supervisor" {
  name     = "rke2-supervisor"
  port     = 9345
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    protocol = "TCP"
    port     = "9345"
  }
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.rke2.arn
  port              = 6443
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.masters.arn
  }
}

resource "aws_lb_listener" "supervisor" {
  load_balancer_arn = aws_lb.rke2.arn
  port              = 9345
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.supervisor.arn
  }
}

resource "aws_lb_target_group_attachment" "master_api_attach" {
  count            = 3
  target_group_arn = aws_lb_target_group.masters.arn
  target_id        = aws_instance.master[count.index].id
  port             = 6443

  depends_on = [aws_lb_listener.api]
}

resource "aws_lb_target_group_attachment" "master_supervisor_attach" {
  count            = 3
  target_group_arn = aws_lb_target_group.supervisor.arn
  target_id        = aws_instance.master[count.index].id
  port             = 9345

  depends_on = [aws_lb_listener.supervisor]
}

output "master_ips" {
  value = aws_instance.master[*].public_ip
}

output "worker_ips" {
  value = aws_instance.worker[*].public_ip
}

output "load_balancer_dns" {
  value = aws_lb.rke2.dns_name
}

output "private_key" {
  value     = tls_private_key.rke2.private_key_pem
  sensitive = true
}

