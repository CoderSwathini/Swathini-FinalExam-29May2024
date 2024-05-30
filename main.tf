
provider "aws" 
{
  region = "ca-central-1"
}

# Fetch the existing VPC
data "aws_vpc" "selected" {
  id = "vpc-0b2c9bf219b146ec8"
}

resource "aws_s3_bucket" "swathinivpbucket" {
  bucket = "unique-example-bucket-name-123456"  
}

resource "aws_iam_role" "example_role" {
  name = "example-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "example_policy" {
  name        = "example-policy"
  description = "A sample policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example_role_policy_attachment" {
  role       = aws_iam_role.example_role.name
  policy_arn = aws_iam_policy.example_policy.arn
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-sg"
  description = "Allow MySQL traffic"
  vpc_id      = data.aws_vpc.selected.id

  # Inbound rules
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  # Outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "example_rds" {
  identifier              = "example-rds"
  engine                  = "mysql"
  instance_class          = "db.t2.micro"
  allocated_storage       = 20
  db_name                 = "awsmetrodb"
  username                = "admin"
  password                = "admin1234"
  vpc_security_group_ids  = [aws_security_group.mysql_sg.id]
  skip_final_snapshot     = true
}

resource "aws_glue_job" "example_glue_job" {
  name     = "example-glue-job"
  role_arn = aws_iam_role.example_role.arn
  command {
    name            = "glueetl"
    script_location = "s3://unique-example-bucket-name-123456/glue-scripts/sample-script.py"  
    python_version  = "3"
  }
  default_arguments = {
    "--job-language" = "python"
  }
}

resource "aws_kms_key" "example_kms_key" {
  description             = "KMS key for encryption"
  deletion_window_in_days = 10
}

resource "aws_lb" "example_alb" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mysql_sg.id]
  subnets            = [
    "subnet-09908f6a48aa5599e", 
    "subnet-0c7d2552520f2d14d",
    "subnet-0b7e761e220c0501",
    "subnet-004749d0686502c7b"
  ]

  enable_deletion_protection = false
}

resource "aws_autoscaling_group" "example_asg" {
  desired_capacity          = 2
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier       = [
    "subnet-09908f6a48aa5599e", 
    "subnet-0c7d2552520f2d14d",
    "subnet-0b7e761e220c0501",
    "subnet-004749d0686502c7b"
  ]

  launch_configuration      = aws_launch_configuration.example_lc.id

  tag {
    key                 = "Name"
    value               = "example-asg"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "example_lc" {
  name          = "example-lc"
  image_id      = "ami-05e5688f9ac7ade41"  
  instance_type = "t2.micro"
  security_groups = [aws_security_group.mysql_sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "example_tg" {
  name     = "example-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id

  health_check {
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "example_listener" {
  load_balancer_arn = aws_lb.example_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_tg.arn
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.example_asg.name
  lb_target_group_arn    = aws_lb_target_group.example_tg.arn
}

output "s3_bucket_name" {
  value = aws_s3_bucket.swathinivpbucket.bucket
}

output "iam_role_name" {
  value = aws_iam_role.example_role.name
}

output "security_group_id" {
  value = aws_security_group.mysql_sg.id
}

output "rds_endpoint" {
  value = aws_db_instance.example_rds.endpoint
}

output "glue_job_name" {
  value = aws_glue_job.example_glue_job.name
}

output "kms_key_arn" {
  value = aws_kms_key.example_kms_key.arn
}

output "alb_dns_name" {
  value = aws_lb.example_alb.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.example_asg.name
}
