resource "aws_vpc" "ksp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = format("vpc-${terraform.workspace}")
  }
}

resource "aws_subnet" "frontend_subnet" {
  vpc_id     = aws_vpc.ksp_vpc.id
  cidr_block = "10.0.0.0/24"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ksp_vpc.id
}

resource "aws_default_route_table" "default_rtb" {
  default_route_table_id = aws_vpc.ksp_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_eip" "nat_gtw_ip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gtw" {
  allocation_id = aws_eip.nat_gtw_ip.id
  subnet_id     = aws_subnet.frontend_subnet.id
}

resource "aws_security_group" "frontend_sg" {
  name   = "sg_frontend"
  vpc_id = aws_vpc.ksp_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.frontend_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.frontend_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.frontend_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}

resource "aws_vpc_security_group_egress_rule" "frontend_sg_egress_rule" {
  security_group_id = aws_security_group.frontend_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

resource "aws_eip" "frontend_ip" {
  domain = "vpc"
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.guacamole_frontend.id
  allocation_id = aws_eip.frontend_ip.id
}

resource "aws_instance" "guacamole_frontend" {
  ami                    = var.guacamole_ami
  instance_type          = var.guacamole_instance_type
  subnet_id              = aws_subnet.frontend_subnet.id
  key_name               = var.guacamole_ssh_key
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  private_ip             = "10.0.0.10"
  user_data_base64 = base64encode(templatefile("${path.module}/templates/guacamole-init.tftpl", {
    postgres_user             = var.postgres_user
    postgres_password         = var.postgres_password
    postgres_db               = var.postgres_db
    public_ip                 = aws_eip.frontend_ip.public_ip
    acme_letsencrypt_endpoint = var.acme_letsencrypt_endpoint[var.env]
    acme_email                = var.acme_email
  }))

  tags = {
    Name = "guacamole-ec2-${terraform.workspace}"
  }
}

resource "aws_ec2_instance_state" "guacamole_frontend_instance_state" {
  instance_id = aws_instance.guacamole_frontend.id
  state       = var.instance_state
}

/* ============== */
/*     Backend    */
/* ============== */

resource "aws_subnet" "backend_subnet" {
  vpc_id     = aws_vpc.ksp_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_route_table" "backend_rtb" {
  vpc_id = aws_vpc.ksp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gtw.id
  }
}

resource "aws_route_table_association" "backend_rtb_assoc" {
  route_table_id = aws_route_table.backend_rtb.id
  subnet_id      = aws_subnet.backend_subnet.id
}

resource "aws_security_group" "backend_sg" {
  name   = "sg_backend"
  vpc_id = aws_vpc.ksp_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_rdp" {
  security_group_id = aws_security_group.backend_sg.id

  cidr_ipv4   = "10.0.0.10/32"
  from_port   = 3389
  ip_protocol = "tcp"
  to_port     = 3389
}

resource "aws_vpc_security_group_egress_rule" "backend_sg_egress_rule" {
  security_group_id = aws_security_group.backend_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

resource "aws_instance" "users_instances" {
  count = length(var.lab_users)

  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.backend_subnet.id
  private_ip             = format("10.0.1.%d", count.index + 1 + 10)
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  tags = {
    Name = format("user-%02.0f-ec2-${terraform.workspace}", count.index + 1)
  }
}

resource "aws_ec2_instance_state" "user_instances_states" {
  count = length(var.lab_users)

  instance_id = aws_instance.users_instances[count.index].id
  state       = var.instance_state
}
