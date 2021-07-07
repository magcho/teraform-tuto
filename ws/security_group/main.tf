


# anti pattern
# モジュール内でproviderを書いてはいけない
# provider "aws"{
#   region = "ap-northeast-1"
# }

# 7.20
variable "name" {}
variable "vpc_id" {}
variable "port" {}
variable "cidr_blocks" {
  type = list(string)
}

# 7.17
# resource "aws_security_group" "example" {
#   name   = "example"
#   vpc_id = aws_vpc.example.id
# }
# 7.18
# resource "aws_security_group_rule" "ingress_example" {
#   type              = "ingress"
#   from_port         = "80"
#   to_port           = "80"
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.example.id
# }

# # 7.19
# resource "aws_security_group" "egress_example" {
#   type              = "egress"
#   from_port         = "0"
#   to_port           = "0"
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.example.id
# }


# 7.20
resource "aws_security_group" "default" {
  name   = var.name
  vpc_id = var.vpc_id
}
resource "aws_security_group_rule" "ingress_example" {
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.cidr_blocks
  security_group_id = aws_security_group.default.id
}
resource "aws_security_group_rule" "egress_example" {
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = var.cidr_blocks
  security_group_id = aws_security_group.default.id
}
output "security_group_id"{
  value = aws_security_group.default.id
}
