


# # private bucket
# resource "aws_s3_bucket" "private" {
#   bucket = "private-tf.magcho.com"
#   acl    = "private"

#   versioning {
#     enabled = true
#   }

#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         sse_algorithm = "AES256"
#       }
#     }
#   }
# }

# # block public assecc bucket
# resource "aws_s3_bucket_public_access_block" "private" {
#   bucket              = aws_s3_bucket.private.id
#   block_public_acls   = true
#   block_public_policy = true
#   ignore_public_acls  = true
#   # restrict_public_buckets = true
# }

# # public bucket & CORS
# resource "aws_s3_bucket" "public" {
#   bucket = "public-tf.magcho.com"
#   acl    = "public-read"

#   cors_rule {
#     allowed_origins = ["https://magcho.com"]
#     allowed_methods = ["GET"]
#     allowed_headers = ["*"]
#     max_age_seconds = 3000
#   }
# }

# ALB logbucket
resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-tf.magcho.com"
  lifecycle_rule {
    enabled = true

    expiration {
      days = "180" #ログの最大保持日数（古いログは消える）
    }
  }
}


# https://qiita.com/ayatothos/items/27024e8168a8b766bcd3#%E7%AC%AC6%E7%AB%A0-%E3%82%B9%E3%83%88%E3%83%AC%E3%83%BC%E3%82%B8
data "aws_elb_service_account" "alb_log" {}

data "aws_iam_policy_document" "alb_log" {
  # albからのログをs3にwriteするためのroleを作るためのIAMポリシー
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${data.aws_elb_service_account.alb_log.id}"]
    }
  }
}
resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json

}
