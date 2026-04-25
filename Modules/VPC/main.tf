resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {

    Name = "${var.environment}-${var.project}-main-vpc"
  }

}

resource "aws_subnet" "public_subnets" {

  count = length(var.public_subnet_cidr)

  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr[count.index]
  availability_zone       = var.subnet_az[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.environment}-${var.project}-public-${var.subnet_az[count.index]}-${var.public_subnet_cidr[count.index]}"
    Tier = "public"
  }


}

resource "aws_subnet" "frotnend_subnets" {
  count = length(var.frontend_subnet_cidr)

  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.frontend_subnet_cidr[count.index]
  availability_zone = var.subnet_az[count.index]
  tags = {
    Name = "${var.environment}-${var.project}-frontend-${var.subnet_az[count.index]}-${var.frontend_subnet_cidr[count.index]}"
    Tier = "frontend"
  }
}

resource "aws_subnet" "backend_subnets" {
  count = length(var.backend_subnet_cidr)

  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.backend_subnet_cidr[count.index]
  availability_zone = var.subnet_az[count.index]
  tags = {
    Name = "${var.environment}-${var.project}-backend-${var.subnet_az[count.index]}-${var.backend_subnet_cidr[count.index]}"
    Tier = "backend"
  }

}

resource "aws_subnet" "database_subnets" {
  count = length(var.database_subnet_cidr)

  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.database_subnet_cidr[count.index]
  availability_zone = var.subnet_az[count.index]
  tags = {
    Name = "${var.environment}-${var.project}-database-${var.subnet_az[count.index]}-${var.database_subnet_cidr[count.index]}"
    Tier = "database"
  }

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${var.environment}-${var.project}-igw"
  }

}


resource "aws_eip" "nat" {
  count  = length(var.subnet_az)
  domain = "vpc"

  tags = {
    Name = "${var.environment}-${var.project}-nat-eip-${count.index}"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_gw" {
  count         = length(var.subnet_az)
  subnet_id     = aws_subnet.public_subnets[count.index].id
  allocation_id = aws_eip.nat[count.index].id
  tags = {
    Name = "${var.environment}-${var.project}-nat-gw-${count.index}-${var.subnet_az[count.index]}"
  }

}

resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.environment}-${var.project}-public-rt"
  }
  depends_on = [aws_vpc.main_vpc]
}
resource "aws_route_table_association" "public_rt_assoc" {
  count          = length(var.public_subnet_cidr)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.rt_public.id

  depends_on = [aws_route_table.rt_public]

}


resource "aws_route_table" "rt_private" {
  count  = length(var.subnet_az)
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }
  tags = {
    Name = "${var.environment}-${var.project}-private-rt"
  }
  depends_on = [aws_vpc.main_vpc]
}



resource "aws_route_table_association" "private_rt_frontend_assoc" {
  count          = length(var.subnet_az)
  subnet_id      = aws_subnet.frotnend_subnets[count.index].id
  route_table_id = aws_route_table.rt_private[count.index].id

  depends_on = [aws_route_table.rt_private]
}

resource "aws_route_table_association" "private_rt_backend_assoc" {
  count          = length(var.subnet_az)
  subnet_id      = aws_subnet.backend_subnets[count.index].id
  route_table_id = aws_route_table.rt_private[count.index].id

  depends_on = [aws_route_table.rt_private]
}


resource "aws_route_table" "rt_database" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.environment}-${var.project}-database-rt"
  }
}

resource "aws_route_table_association" "rt_database_assoc" {
  count       = length(var.subnet_az)
  subnet_id      = aws_subnet.database_subnets[count.index].id
  route_table_id = aws_route_table.rt_database.id

  depends_on = [aws_route_table.rt_database]

}



