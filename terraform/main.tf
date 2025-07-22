resource "aws_vpc" "openlab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = format("openlab-vpc-${terraform.workspace}")
  }
}

resource "aws_subnet" "frontend_subnet" {
  vpc_id     = aws_vpc.openlab_vpc.id
  cidr_block = "10.0.0.0/24"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.openlab_vpc.id
}

resource "aws_default_route_table" "default_rtb" {
  default_route_table_id = aws_vpc.openlab_vpc.default_route_table_id

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
  name   = "frontend-security-group"
  vpc_id = aws_vpc.openlab_vpc.id
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

resource "aws_subnet" "backend_subnets" {
  count      = length(var.lab_users)
  vpc_id     = aws_vpc.openlab_vpc.id
  cidr_block = format("10.0.%d.0/24", count.index + 1)
}

resource "aws_route_table" "backend_rtb" {
  vpc_id = aws_vpc.openlab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gtw.id
  }
}

resource "aws_route_table_association" "backend_rtb_assoc" {
  count          = length(var.lab_users)
  route_table_id = aws_route_table.backend_rtb.id
  subnet_id      = aws_subnet.backend_subnets[count.index].id
}

resource "aws_security_group" "backend_security_groups" {
  count  = length(var.lab_users)
  name   = format("backend-security-group-%d", count.index + 1)
  vpc_id = aws_vpc.openlab_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_rdp" {
  count             = length(var.lab_users)
  security_group_id = aws_security_group.backend_security_groups[count.index].id

  cidr_ipv4   = "10.0.0.10/32"
  from_port   = 3389
  ip_protocol = "tcp"
  to_port     = 3389
}

resource "aws_vpc_security_group_egress_rule" "allow_to_any" {
  count             = length(var.lab_users)
  security_group_id = aws_security_group.backend_security_groups[count.index].id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

resource "aws_vpc_security_group_ingress_rule" "allow_from_subnet" {
  count             = length(var.lab_users)
  security_group_id = aws_security_group.backend_security_groups[count.index].id

  cidr_ipv4   = aws_subnet.backend_subnets[count.index].cidr_block
  ip_protocol = -1
}

locals {
  instances = [
    for key, pair in setproduct(aws_subnet.backend_subnets, var.instances) : {
      ami           = pair[1].ami
      instance_type = pair[1].instance_type
      subnet_id     = pair[0].id
      private_ip    = cidrhost(pair[0].cidr_block, key % length(var.instances) + 11)
    }
  ]
}

resource "aws_instance" "users_instances" {
  for_each = tomap({
    for key, instance in local.instances : key => instance
  })

  ami                    = each.value.ami
  instance_type          = each.value.instance_type
  subnet_id              = each.value.subnet_id
  private_ip             = each.value.private_ip
  vpc_security_group_ids = [aws_security_group.backend_security_groups[floor(each.key / length(var.instances))].id]

  tags = {
    Name = format("user-%02.0f-ec2-${terraform.workspace}", floor(each.key / length(var.instances)) + 1)
  }
}

resource "aws_ec2_instance_state" "user_instances_states" {
  count = length(var.lab_users)

  instance_id = aws_instance.users_instances[count.index].id
  state       = var.instance_state
}
