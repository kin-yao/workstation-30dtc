output "primary_bucket" {
  value = aws_s3_bucket.primary.bucket
}

output "primary_region" {
  value = aws_s3_bucket.primary.region
}

output "replica_bucket" {
  value = aws_s3_bucket.replica.bucket
}

output "replica_region" {
  value = aws_s3_bucket.replica.region
}

output "replication_role_arn" {
  value = aws_iam_role.replication.arn
}