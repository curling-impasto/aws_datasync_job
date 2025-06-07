variable "customer" {
  type        = string
  description = "Primary customer"
}

variable "source_bucket_arn" {
  description = "Sourec bucket ARN"
  type        = string
}

variable "destination_bucket_arn" {
  description = "Destination bucket ARN"
  type        = string
}

variable "source_bucket_folder" {
  description = "Destination bucket Folder name"
  type        = string
}

variable "destination_bucket_folder" {
  description = "Destination bucket Folder name"
  type        = string
}

variable "destination_account_id" {
  description = "Destination AWS account"
  type        = string
}

variable "exclude_patterns" {
  description = "List of patterns to exclude from the DataSync task"
  type        = list(string)
  default     = ["*COUNTERRECORD*"]
}

variable "include_patterns" {
  description = "List of patterns to include in the DataSync task"
  type        = list(string)
  default     = ["*CALLRECORD*", "*PADSRECORD*", "*SMSRECORD*"]
}

# variable "schedule_hours" {
#   description = "How often to run the datasync Job"
#   type        = string
#   default     = null
# }

variable "schedule_minutes" {
  description = "How often to run the datasync Job"
  type        = string
  default     = "10"
}
