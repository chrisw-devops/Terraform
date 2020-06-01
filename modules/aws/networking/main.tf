data "aws_availability_zones" "region_azs" {}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name  = var.vpc_name
  }
}

resource "aws_subnet" "public_subnets" {
  cidr_block = cidrsubnet(var.cidr_block, var.subnet_newbits, count.index)
  vpc_id = aws_vpc.main.id
  count = length(data.aws_availability_zones.region_azs.names)
  tags = {
    Name = join("", ["Public (", data.aws_availability_zones.region_azs.names[count.index], ")"])
  }
}

resource "aws_subnet" "private_subnets" {
  cidr_block = cidrsubnet(var.cidr_block, var.subnet_newbits, count.index + length(data.aws_availability_zones.region_azs.names))
  vpc_id = aws_vpc.main.id
  count = length(data.aws_availability_zones.region_azs.names)
  tags = {
    Name = join("", ["Private (", data.aws_availability_zones.region_azs.names[count.index], ")"])
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_eip" "main" {
  vpc = true
  count = length(data.aws_availability_zones.region_azs.names)
}

resource "aws_nat_gateway" "main" {
  count = length(data.aws_availability_zones.region_azs.names)
  allocation_id = aws_eip.main[count.index].id
  subnet_id = aws_subnet.public_subnets[count.index].id
  tags = {
    Name = join("", ["NAT Gateway (", data.aws_availability_zones.region_azs.names[count.index], ")"])
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = join(" ", [var.vpc_name, "Public Route Table"])
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  count = length(data.aws_availability_zones.region_azs.names)

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = join("", [var.vpc_name, " Private Route Table (", data.aws_availability_zones.region_azs.names[count.index], ")"])
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  route_table_id = aws_route_table.public_route_table.id
  count = length(data.aws_availability_zones.region_azs.names)
  subnet_id = aws_subnet.public_subnets[count.index].id
}

resource "aws_route_table_association" "private_route_table_association" {
  route_table_id = aws_route_table.private_route_table[count.index].id
  count = length(data.aws_availability_zones.region_azs.names)
  subnet_id = aws_subnet.private_subnets[count.index].id
}