# ECS Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "url-shortener-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "url-shortener-execution-role"
  }
}

# Attach AWS Managed policy for standard task Execution 
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2. ECS Task Role (Used by your Application Code to access DynamoDB)
resource "aws_iam_role" "ecs_task_role" {
  name = "url-shortener-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "url-shortener-task-role"
  }
}


# Fine-grained IAM Policy for DynamoDB (Least Privilege)
resource "aws_iam_policy" "dynamodb_access_policy" {
  name        = "url-shortener-dynamodb-policy"
  description = "Allows ECS tasks to read and write to the URL Shortener DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.url_shortener.arn
      }
    ]
  })
}

# Attach the DynamoDB policy to the Task Role
resource "aws_iam_role_policy_attachment" "ecs_task_dynamodb_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.dynamodb_access_policy.arn
}