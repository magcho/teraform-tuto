


provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "handson"
  }
}

resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name = "handson-public-1a"
  }
}
resource "aws_subnet" "public_1c" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name = "handson-public-1c"
  }
}
resource "aws_subnet" "public_1d" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-northeast-1d"
  cidr_block        = "10.0.3.0/24"
  tags = {
    Name = "handson-public-1d"
  }
}

resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.10.0/24"
  tags = {
    Name = "handson-private-1a"
  }
}
resource "aws_subnet" "private_1c" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.20.0/24"
  tags = {
    Name = "handson-private-1c"
  }
}
resource "aws_subnet" "private_1d" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-northeast-1d"
  cidr_block        = "10.0.30.0/24"
  tags = {
    Name = "handson-private-1d"
  }
}


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson"
  }
}


resource "aws_eip" "nat_1a" {
  vpc = true
  tags = {
    Name = "handson-natgw-1a"
  }
}
resource "aws_nat_gateway" "nat_1a" {
  subnet_id     = aws_subnet.public_1a.id
  allocation_id = aws_eip.nat_1a.id
  tags = {
    Name = "hadson-1a"
  }
}
resource "aws_eip" "nat_1c" {
  vpc = true
  tags = {
    Name = "handson-natgw-1c"
  }
}
resource "aws_nat_gateway" "nat_1c" {
  subnet_id     = aws_subnet.public_1c.id
  allocation_id = aws_eip.nat_1c.id
  tags = {
    Name = "hadson-1c"
  }
}
resource "aws_eip" "nat_1d" {
  vpc = true
  tags = {
    Name = "handson-natgw-1d"
  }
}
resource "aws_nat_gateway" "nat_1d" {
  subnet_id     = aws_subnet.public_1d.id
  allocation_id = aws_eip.nat_1d.id
  tags = {
    Name = "hadson-1d"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson-public"
  }
}
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id

}
resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_1d" {
  subnet_id      = aws_subnet.public_1d.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson-private-1a"
  }
}
resource "aws_route_table" "private_1c" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson-private-1c"
  }
}
resource "aws_route_table" "private_1d" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson-private-1d"
  }
}

resource "aws_route" "private_1a" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1a.id
  nat_gateway_id         = aws_nat_gateway.nat_1a.id
}
resource "aws_route" "private_1c" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1c.id
  nat_gateway_id         = aws_nat_gateway.nat_1c.id
}
resource "aws_route" "private_1d" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1d.id
  nat_gateway_id         = aws_nat_gateway.nat_1d.id
}
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}
resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private_1c.id
}
resource "aws_route_table_association" "private_1d" {
  subnet_id      = aws_subnet.private_1d.id
  route_table_id = aws_route_table.private_1d.id
}

# ALB
resource "aws_security_group" "alb" {
  name        = "handson-alb"
  description = "handson-alb"
  vpc_id      = aws_vpc.main.id


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "handson-alb"
  }
}
resource "aws_security_group_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}
resource "aws_alb" "main" {
  load_balancer_type = "application"
  name               = "handson"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1c.id, aws_subnet.public_1d.id]
}

resource "aws_alb_listener" "main" {
  port     = "80"
  protocol = "HTTP"

  load_balancer_arn = aws_alb.main.arn
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "ok"
    }
  }
}
