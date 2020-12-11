data "aws_iam_policy_document" "s3_crr" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetReplicationConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold"
    ]

    resources = flatten([
      "arn:aws:s3:::${var.name_prefix}${var.name_suffix}",
      "arn:aws:s3:::${var.name_prefix}${var.name_suffix}/*",
      local.replication_bucket_arn,
      local.replication_bucket_object_arn
    ])
  }

  statement {
    actions = [

      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = flatten([
      "arn:aws:s3:::${var.name_prefix}${var.name_suffix}/*",
      local.replication_bucket_object_arn
    ])
  }
}

resource "aws_iam_role" "s3_crr" {
  count              = var.destination_buckets != [] ? 1 : 0
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role.json
  name               = "${var.name_prefix}${var.name_suffix}-s3crr"
  tags               = var.tags
}

resource "aws_iam_role_policy" "s3_crr" {
  count  = var.destination_buckets != [] ? 1 : 0
  name   = "${var.name_prefix}${var.name_suffix}-s3crr"
  policy = data.aws_iam_policy_document.s3_crr.json
  role   = aws_iam_role.s3_crr.0.id
}
