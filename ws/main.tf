

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_iam_policy_document" "allow_describe_regions" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeRegions"]
    resources = ["*"]
  }
}
module "describe_regions_for_ec2" {
  source     = "./iam_role"
  name       = "describe-regions-for-ec2"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.allow_describe_regions.json
}

module "s3_buckets" {
  source = "./s3"
}

module "vpc" {
  source = "./vpc"
}

module "alb" {
  source = "./alb"
  subnets = [
    module.vpc.aws_subnet_public_0_id,
    module.vpc.aws_subnet_public_1_id,
  ]
  alb_log_s3_bucket = module.s3_buckets.aws_s3_bucket_alb_log_id
  vpc_id            = module.vpc.aws_vpc_id
}

module "ecs" {
  source = "./ecs"
  subnets = [
    module.vpc.aws_subnet_private_0_id,
    module.vpc.aws_subnet_private_1_id,
  ]
  lb_target_group = module.alb.lb_target_group
  vpc_id          = module.vpc.aws_vpc_id
  vpc_cidr_block  = module.vpc.aws_vpc_cidr_block
}
