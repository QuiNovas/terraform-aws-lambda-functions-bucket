resource "aws_s3_bucket" "lambda" {
  bucket = "${var.name_prefix}${var.name_suffix}"

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

resource "aws_s3_bucket_replication_configuration" "lambda" {
  count = var.replication_enabled ? 1 : 0
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.lambda]

  role   = aws_iam_role.s3_crr.0.arn
  bucket = aws_s3_bucket.lambda.id
  dynamic "rule" {
    for_each = var.destination_buckets
    content {
      id       = rules.value
      priority = index(var.destination_buckets, rule.value)
      status   = "Enabled"

      destination {
        bucket = "arn:aws:s3:::${rule.value}"
      }

      filter {}
    }
  }
}

resource "aws_s3_bucket_logging" "lambda" {
  count         = var.logging ? 1 : 0
  bucket        = aws_s3_bucket.lambda.id
  target_bucket = var.log_bucket_id
  target_prefix = "s3/${var.name_prefix}${var.name_suffix}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "lambda" {
  bucket = aws_s3_bucket.lambda.bucket

  rule {
    id = "versions"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    expiration {
      expired_object_delete_marker = true
    }

    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 60
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_versioning" "lambda" {
  bucket = aws_s3_bucket.lambda.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "s3:*",
    ]
    condition {
      test = "Bool"
      values = [
        "false",
      ]
      variable = "aws:SecureTransport"
    }
    effect = "Deny"
    principals {
      identifiers = [
        "*",
      ]
      type = "AWS"
    }
    resources = [
      aws_s3_bucket.lambda.arn,
      "${aws_s3_bucket.lambda.arn}/*",
    ]
    sid = "DenyUnsecuredTransport"
  }
  statement {
    actions = [
      "s3:PutObject",
    ]
    condition {
      test = "StringNotEquals"
      values = [
        "AES256",
      ]
      variable = "s3:x-amz-server-side-encryption"
    }
    effect = "Deny"
    principals {
      identifiers = [
        "*",
      ]
      type = "AWS"
    }
    resources = [
      aws_s3_bucket.lambda.arn,
      "${aws_s3_bucket.lambda.arn}/*",
    ]
    sid = "DenyIncorrectEncryptionHeader"
  }
  statement {
    actions = [
      "s3:PutObject",
    ]
    condition {
      test = "Null"
      values = [
        "true",
      ]
      variable = "s3:x-amz-server-side-encryption"
    }
    effect = "Deny"
    principals {
      identifiers = [
        "*",
      ]
      type = "AWS"
    }
    resources = [
      aws_s3_bucket.lambda.arn,
      "${aws_s3_bucket.lambda.arn}/*",
    ]
    sid = "DenyUnencryptedObjectUploads"
  }
  statement {
    actions = [
      "s3:GetObject*",
    ]
    principals {
      identifiers = flatten([
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        var.cross_account_users,
      ])
      type = "AWS"
    }
    resources = [
      aws_s3_bucket.lambda.arn,
      "${aws_s3_bucket.lambda.arn}/*",
    ]
    sid = "AllowCrossAccountAccess"
  }
}

resource "aws_s3_bucket_policy" "lambda" {
  bucket = aws_s3_bucket.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_s3_bucket_public_access_block" "lambda" {
  count                   = var.block_all_public_access ? 1 : 0
  bucket                  = aws_s3_bucket.lambda.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}