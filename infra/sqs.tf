resource "aws_sqs_queue" "chat_messages_dlq" {
  name                      = "${var.project}-messages-dlq"
  message_retention_seconds = 604800

  tags = {
    Project = var.project
  }
}

resource "aws_sqs_queue" "chat_messages" {
  name                       = "${var.project}-messages"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.chat_messages_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Project = var.project
  }
}
