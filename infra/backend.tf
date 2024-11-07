# Backend configuration
terraform {
  backend "s3" {
    bucket         = "terraform-states-hello-world-5963881-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-hello-world-5963881-dev"
  }
}

# Create a new S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-states-${var.project_name}-${var.environment}"

  lifecycle {
    prevent_destroy = true
  }
}
# Create a new DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks-${var.project_name}-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
# Block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# Bucket versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
