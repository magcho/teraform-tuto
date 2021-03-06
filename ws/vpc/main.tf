

# 7.1
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16" # Classless Inter-Domain Routing (CIDR)
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "example"
  }
}


# 7.2
# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.example.id
#   cidr_block              = "10.0.0.0/24"
#   map_public_ip_on_launch = true
#   availability_zone       = "ap-northeast-1a"
# }


# 7.12
resource "aws_subnet" "public_0" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  # map_public_ip_on_launch = true
  tags = {
    Name = "public_0"
  }
}
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"
  # map_public_ip_on_launch = true
  tags = {
    Name = "public_1"
  }
}

# 7.3
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}


# 7.4
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "example_public"
  }
}


# 7.5
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}


# 7.6
# resource "aws_route_table_association" "public" {
#   # ルートテーブルとVPCの関連付け省略するとVPCデフォルトのルートテーブルが利用されるが、tfのコントロール外なのでそれはアンチパターン
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }


# 7.13
resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}


# 7.7
# resource "aws_subnet" "private" {
#   vpc_id                  = aws_vpc.example.id
#   cidr_block              = "10.0.64.0/24"
#   availability_zone       = "ap-northeast-1a"
#   map_public_ip_on_launch = true
# }


# 7.14
resource "aws_subnet" "private_0" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.65.0/24"
  availability_zone = "ap-northeast-1a"
  # map_public_ip_on_launch = false
  tags = {
    Name = "private_0"
  }
}
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.66.0/24"
  availability_zone = "ap-northeast-1c"
  # map_public_ip_on_launch = false
  tags = {
    Name = "private_1"
  }
}

# 7.8
# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.example.id
# }
# resource "aws_route_table_association" "private" {
#   subnet_id      = aws_subnet.private.id
#   route_table_id = aws_route_table.private.id
# }

# 7.16
resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "exmaple_prviate0"
  }
}
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "exmaple_prviate1"
  }
}
resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}


# 7.9
# resource "aws_eip" "nat_gateway" {
#   vpc        = true
#   depends_on = [aws_internet_gateway.example]
# }


# 7.10
# resource "aws_nat_gateway" "example" {
#   # private subnetは外部に繋がらない(docker pull等ができない)ので外部と繋がる手段を作る
#   allocation_id = aws_eip.nat_gateway.id
#   subnet_id     = aws_subnet.private.id
#   depends_on    = [aws_internet_gateway.example]
# }

# 7.15
resource "aws_eip" "nat_gateway_0" {
  vpc        = true
  depends_on = [aws_internet_gateway.example]
  tags = {
    Name = "0"
  }
}
resource "aws_eip" "nat_gateway_1" {
  vpc        = true
  depends_on = [aws_internet_gateway.example]
  tags = {
    Name = "1"
  }
}
resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_0.id
  depends_on    = [aws_internet_gateway.example]
}
resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.example]
}


# 7.11
# resource "aws_route" "private" {
#   route_table_id         = aws_route_table.private.id
#   nat_gateway_id         = aws_nat_gateway.example.id
#   destination_cidr_block = "0.0.0.0/0"
# }

# 7.21
module "example_sg" {
  source      = "../security_group"
  name        = "module-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

output "aws_subnet_public_0_id" {
  value = aws_subnet.public_0.id
}
output "aws_subnet_public_1_id" {
  value = aws_subnet.public_1.id
}
output "aws_vpc_id" {
  value = aws_vpc.example.id
}
output "aws_vpc_cidr_block" {
  value = aws_vpc.example.cidr_block
}

output "aws_subnet_private_0_id" {
  value = aws_subnet.private_0.id
}
output "aws_subnet_private_1_id" {
  value = aws_subnet.private_1.id
}
