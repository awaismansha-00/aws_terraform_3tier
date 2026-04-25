resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_name}-${var.environment}"
   
  tags = {
    Name        = "${var.bucket_name}-${var.environment}"
    Environment = var.environment
  }
}