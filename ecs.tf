# 1. Security Group for ECS Tasks 

resource "aws_security_group" "ecs_task" {
  name        = "url_shortener-ecs-tasks-sg"
  description = "Allow_traffic_strictly_from_ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow_HTTP_from_ALB_only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "url-shortener-ecs-tasks-sg"
  }
}

# 2. ECS Cluster (Logical grouping for tasks)
resource "aws_ecs_cluster" "main" {
  name = "url-shortener-cluster"

  tags = {
    Name = "url-shortener-cluster"
  }
}

# 3. CloudWatch Log Group for Application Container Output
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/url-shortener"
  retention_in_days = 7
}

# 4. ECS Task Definition (Blueprint for running the container)
resource "aws_ecs_task_definition" "app" {
  family                   = "url-shortener-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 512 MB

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "url-shortener-app"
      image     = "008482603388.dkr.ecr.us-east-1.amazonaws.com/url-shortener-app:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DYNAMODB_TABLE"
          value = aws_dynamodb_table.url_shortener.name
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = "us-east-1" # Make sure this matches your provider region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# 5. ECS Service (Launches and manages Fargate tasks in private subnets)
resource "aws_ecs_service" "main" {
  name            = "url-shortener-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [aws_subnet.Public_1.id, aws_subnet.Public_2.id]
    security_groups  = [aws_security_group.ecs_task.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "url-shortener-app"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]
}


