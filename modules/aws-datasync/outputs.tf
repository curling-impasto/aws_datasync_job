output "datasync_task_arn" {
  description = "ARN of the deployed Lambda function"
  value       = aws_datasync_task.task.arn
}
