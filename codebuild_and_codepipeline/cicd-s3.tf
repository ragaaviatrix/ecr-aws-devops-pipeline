resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = var.pipeline_s3_bucket
} 