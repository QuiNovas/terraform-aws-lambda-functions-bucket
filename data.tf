data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "s3_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      identifiers = ["s3.amazonaws.com"]
      type        = "Service"
    }
  }
}