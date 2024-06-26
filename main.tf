#module "aws_cognito_user_pool" {
#  source         = "lgallard/cognito-user-pool/aws"
#  user_pool_name = var.user_pool_name
#  tags           = var.tags
#}
#
#resource "aws_cognito_user_pool_client" "video2mp3_client" {
#  name = "video2mp3-client"
#
#  user_pool_id = module.aws_cognito_user_pool.id
#
#  generate_secret     = true
#  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH"]
#}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix = "video2mp3repo-"
  force_destroy = true

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_signer_signing_profile" "video2mp3" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = "Video2MP3_Infra"

  signature_validity_period {
    value = 3
    type  = "MONTHS"
  }
}

module "iam" {
  source = "./modules/iam"
}

module "lambda" {
  source                     = "./modules/lambda"
  s3_bucket_id               = module.s3_bucket.s3_bucket_id
  signer_profile             = aws_signer_signing_profile.video2mp3.name
  signer_profile_version_arn = aws_signer_signing_profile.video2mp3.version_arn
}
