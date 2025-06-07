
# IAM Role for DataSync
resource "aws_iam_role" "datasync_role" {
  name               = "${var.customer}-datasync-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "datasync.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# IAM Policy for DataSync
resource "aws_iam_policy" "datasync_policy" {
  provider = aws

  name        = "${var.customer}-datasync-policy"
  description = "IAM policy for DataSync"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSDataSyncS3BucketPermissions",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": [
                "${var.source_bucket_arn}",
                "${var.destination_bucket_arn}"
            ]
        },
        {
            "Sid": "AWSDataSyncS3ObjectPermissions",
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:GetObjectTagging",
                "s3:GetObjectVersion",
                "s3:GetObjectVersionTagging",
                "s3:ListMultipartUploadParts",
                "s3:PutObject",
                "s3:PutObjectTagging"
            ],
            "Resource": [
                "${var.source_bucket_arn}/*",
                "${var.destination_bucket_arn}/*"
            ]
        }
    ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "datasync_policy_attach" {
  role       = aws_iam_role.datasync_role.name
  policy_arn = aws_iam_policy.datasync_policy.arn
}

# Source Location
resource "aws_datasync_location_s3" "source_location" {
  s3_bucket_arn = var.source_bucket_arn
  subdirectory  = coalesce(var.source_bucket_folder, "/")

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_role.arn
  }
}


# Destination Location
resource "aws_datasync_location_s3" "destination_location" {
  s3_bucket_arn = var.destination_bucket_arn
  subdirectory  = "/${var.destination_bucket_folder}"
  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_role.arn
  }
}

# Cloudwatch Log group
resource "aws_cloudwatch_log_group" "datasync_log_group" {
  name              = "/aws/datasync/${var.customer}-cdr-task"
  retention_in_days = 5

  tags = {
    Name = "/aws/datasync/${var.customer}-cdr-task"
  }
}

# Datasync Task
resource "aws_datasync_task" "task" {
  name                     = "${var.customer}-cdr-datasync-task"
  source_location_arn      = aws_datasync_location_s3.source_location.arn
  destination_location_arn = aws_datasync_location_s3.destination_location.arn
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.datasync_log_group.arn

  options {
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    overwrite_mode         = "NEVER"
    preserve_deleted_files = "REMOVE"
    posix_permissions      = "NONE"
    bytes_per_second       = -1
    uid                    = "NONE"
    gid                    = "NONE"
    preserve_devices       = "NONE"
    log_level              = "TRANSFER"
  }

  # dynamic "schedule" {
  #   for_each = var.schedule_hours != null ? [1] : []
  #   content {
  #     schedule_expression = "rate(${var.schedule_hours} hours)"
  #   }
  # }

  excludes {
    filter_type = "SIMPLE_PATTERN"
    value       = join("|", var.exclude_patterns)
  }

  includes {
    filter_type = "SIMPLE_PATTERN"
    value       = join("|", var.include_patterns)
  }
}


# IAM Role for EventBridge Scheduler
resource "aws_iam_role" "eventbridge_scheduler_role" {
  name = "${var.customer}-datasync-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "scheduler.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy allowing to start the DataSync task
resource "aws_iam_role_policy" "eventbridge_scheduler_policy" {
  name = "${var.customer}-datasync-eventbridge-policy"
  role = aws_iam_role.eventbridge_scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "datasync:StartTaskExecution",
      Resource = aws_datasync_task.task.arn
    }]
  })
}

# EventBridge Scheduler Schedule
resource "aws_scheduler_schedule" "datasync_trigger" {
  name       = "${var.customer}-datasync-trigger"
  group_name = "default"

  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 5
  }

  schedule_expression = "rate(${var.schedule_minutes} minutes)" # Customize your cron or rate expression

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:datasync:startTaskExecution" # This is how EventBridge Scheduler uses AWS SDK integration
    role_arn = aws_iam_role.eventbridge_scheduler_role.arn

    input = jsonencode({
      TaskArn = aws_datasync_task.task.arn
    })
  }
}
