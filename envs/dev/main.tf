# sample code.
module "mobifone_datasync_setup" {
  source = "../../modules/aws-datasync"

  customer                  = "sample"
  source_bucket_arn         = "arn:aws:s3:::sample-source"
  source_bucket_folder      = "/source"
  destination_bucket_arn    = "arn:aws:s3:::sample-target"
  destination_bucket_folder = "/destination"
  destination_account_id    = "123456789012"
  include_patterns          = ["/REAL*", ]
  exclude_patterns          = ["/TEST*"]
  schedule_minutes          = "30"
}
