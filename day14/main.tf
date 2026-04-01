# Default provider — primary region
provider "aws" {
  region = "eu-north-1"
}

# Aliased provider — secondary region for the replica bucket
# Every resource that needs to deploy here must explicitly reference
# this provider with provider = aws.eu_west
provider "aws" {
  alias  = "eu_west"
  region = "eu-west-1"
}

# --- IAM role for S3 replication ---
# S3 needs permission to read from the source bucket and write to the
# destination bucket. This role grants that.

data "aws_iam_policy_document" "replication_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replication" {
  name               = "day14-s3-replication-role"
  assume_role_policy = data.aws_iam_policy_document.replication_assume.json
}

data "aws_iam_policy_document" "replication" {
  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.primary.arn]
  }

  statement {
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]
    resources = ["${aws_s3_bucket.primary.arn}/*"]
  }

  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags"
    ]
    resources = ["${aws_s3_bucket.replica.arn}/*"]
  }
}

resource "aws_iam_role_policy" "replication" {
  name   = "day14-replication-policy"
  role   = aws_iam_role.replication.id
  policy = data.aws_iam_policy_document.replication.json
}

# --- Primary bucket in eu-north-1 ---
# Uses the default provider — no provider argument needed.

resource "aws_s3_bucket" "primary" {
  bucket = "day14-primary-711387095761"

  tags = {
    Name   = "day14-primary"
    Region = "eu-north-1"
  }
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- Replica bucket in eu-west-1 ---
# Uses the aliased provider — provider argument is required.
# Without it, Terraform would try to create this in eu-north-1.

resource "aws_s3_bucket" "replica" {
  provider = aws.eu_west
  bucket   = "day14-replica-711387095761"

  tags = {
    Name   = "day14-replica"
    Region = "eu-west-1"
  }
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.eu_west
  bucket   = aws_s3_bucket.replica.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- Replication configuration ---
# Versioning must be enabled on both buckets before this works.
# The depends_on ensures versioning is set up first.

resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.replica
  ]
}