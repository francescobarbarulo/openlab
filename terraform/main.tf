resource "aws_vpc" "openlab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = terraform.workspace
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

resource "aws_key_pair" "guacamole_ssh_key" {
  key_name   = terraform.workspace
  public_key = var.guacamole_ssh_key
}

resource "aws_instance" "guacamole_frontend" {
  ami                    = var.guacamole_ami
  instance_type          = var.guacamole_instance_type
  subnet_id              = aws_subnet.frontend_subnet.id
  key_name               = aws_key_pair.guacamole_ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  private_ip             = "10.0.0.10"

  tags = {
    Name = "${terraform.workspace}-guacamole"
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
  for_each   = toset(var.lab_users)
  vpc_id     = aws_vpc.openlab_vpc.id
  cidr_block = "10.0.${index(var.lab_users, each.key) + 1}.0/24"
}

resource "aws_route_table" "backend_rtb" {
  vpc_id = aws_vpc.openlab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gtw.id
  }
}

resource "aws_route_table_association" "backend_rtb_assoc" {
  for_each       = toset(var.lab_users)
  route_table_id = aws_route_table.backend_rtb.id
  subnet_id      = aws_subnet.backend_subnets[each.key].id
}

resource "aws_security_group" "backend_security_groups" {
  for_each = toset(var.lab_users)
  name     = "backend-security-group-${each.key}"
  vpc_id   = aws_vpc.openlab_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_rdp" {
  for_each          = toset(var.lab_users)
  security_group_id = aws_security_group.backend_security_groups[each.key].id
  cidr_ipv4         = "10.0.0.10/32"
  from_port         = 3389
  ip_protocol       = "tcp"
  to_port           = 3389
}

resource "aws_vpc_security_group_egress_rule" "allow_to_any" {
  for_each          = toset(var.lab_users)
  security_group_id = aws_security_group.backend_security_groups[each.key].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

resource "aws_vpc_security_group_ingress_rule" "allow_from_subnet" {
  for_each          = toset(var.lab_users)
  security_group_id = aws_security_group.backend_security_groups[each.key].id
  cidr_ipv4         = aws_subnet.backend_subnets[each.key].cidr_block
  ip_protocol       = -1
}

locals {
  user_instances = {
    for pair in flatten([
      for i, user in var.lab_users : [
        for j, instance in var.instances : {
          key           = "${user}-${instance.name}"
          user          = user
          user_index    = i
          name          = instance.name
          ami           = instance.ami
          instance_type = instance.instance_type
          subnet_id     = aws_subnet.backend_subnets[user].id
          private_ip    = cidrhost(aws_subnet.backend_subnets[user].cidr_block, j + 11)
          password      = instance.password
          vm_user       = instance.user
        }
      ]
    ]) : pair.key => pair
  }
}

resource "aws_instance" "users_instances" {
  for_each = local.user_instances

  ami           = each.value.ami
  instance_type = each.value.instance_type
  subnet_id     = each.value.subnet_id
  private_ip    = each.value.private_ip
  vpc_security_group_ids = [
    aws_security_group.backend_security_groups[each.value.user].id
  ]

  tags = {
    Name = "${terraform.workspace}-${each.value.name}-${each.value.user}"
  }
}

resource "aws_ec2_instance_state" "user_instances_states" {
  for_each = local.user_instances

  instance_id = aws_instance.users_instances[each.key].id
  state       = var.instance_state
}
