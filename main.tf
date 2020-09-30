resource "aws_s3_bucket" "lambda" {
  bucket = "${var.name_prefix}${var.name_suffix}"

  lifecycle {
    prevent_destroy = true
  }

  lifecycle_rule {
    abort_incomplete_multipart_upload_days = 7
    id                                     = "versions"
    enabled                                = true

    expiration {
      expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      days = 60
    }

    noncurrent_version_transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }

  logging {
    target_bucket = var.log_bucket_id
    target_prefix = "s3/${var.name_prefix}${var.name_suffix}"
  }

  versioning {
    enabled = true
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