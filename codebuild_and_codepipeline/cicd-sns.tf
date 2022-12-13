resource "aws_sns_topic" "approval_alerts" {
  name = var.topic_name
}

resource "aws_sns_topic_subscription" "approval_alerts_email_target" {
  topic_arn = aws_sns_topic.approval_alerts.arn
  protocol  = "email"
  endpoint  = var.email_id
}