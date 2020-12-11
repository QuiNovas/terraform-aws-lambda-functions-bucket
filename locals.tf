locals {
  replication_bucket_arn        = formatlist("arn:aws:s3:::%s", var.destination_buckets)
  replication_bucket_object_arn = formatlist("arn:aws:s3:::%s/*", var.destination_buckets)
}