provider "aws" {
  region = "us-east-1"
}

# Try to reference existing ECR repo
data "aws_ecr_repository" "existing" {
  name = "task-tracker-api"
}

# Conditionally create ECR repo if not found
resource "aws_ecr_repository" "app_repo" {
  count = length(try(data.aws_ecr_repository.existing.id, [])) == 0 ? 1 : 0
  name  = "task-tracker-api"
}

locals {
  ecr_repo_url = length(try(data.aws_ecr_repository.existing.id, [])) > 0 ? data.aws_ecr_repository.existing.repository_url : aws_ecr_repository.app_repo[0].repository_url
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "lb_sg" {
  name        = "load-balancer-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  # Allow ALB traffic to EC2
# change from 8000 to 80 DS 7.15
ingress {
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  ## added cidr blocks']
  cidr_blocks = ["0.0.0.0/0"]
}

# (Optional) Allow direct browser access to EC2 for testing
#commented out block to test:
#ingress {
  #from_port   = 8000
  #to_port     = 8000
  #protocol    = "tcp"
  #cidr_blocks = ["0.0.0.0/0"]
#}
 # ingress {
 #   from_port       = 8000
  #  to_port         = 8000
  #  protocol        = "tcp"
 #   security_groups = [aws_security_group.lb_sg.id]
   # description     = "Allow ALB to access app"
#}
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.lb_sg.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami                    = "ami-0c101f26f147fa7fd" # Amazon Linux 2023 (check for updates)
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_a.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "task_tracker" # Replace with your actual EC2 key pair name

 # user_data = <<-EOF
  #            #!/bin/bash
   #           yum update -y
    #          amazon-linux-extras install docker -y
     #         service docker start
      #        usermod -a -G docker ec2-user
       #       aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${local.ecr_repo_url}
        #      docker pull ${local.ecr_repo_url}:latest
         #     docker run -d -p 8000:8000 ${local.ecr_repo_url}:latest
          #    EOF

#user_data = <<-EOF
            #!/bin/bash
           # yum update -y
           # yum install -y python3 git

            # Move to home directory
           # cd /home/ec2-user

            # Clone your GitHub repo
            #git clone https://github.com/byui-devops/HashQueens.git
           # cd HashQueens

            # Install dependencies
           # pip3 install -r requirements.txt

            # Run the app (make sure the entry point matches your app file)
           # nohup python3 app.py > output.log 2>&1 &
            #EOF
user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y python3 python3-pip git

  # Move to home directory
  cd /home/ec2-user

  # Clean up any existing clone
  rm -rf HashQueens

  # Clone your GitHub repo
  git clone https://github.com/byui-devops/HashQueens.git
  cd HashQueens/app

  # Upgrade pip and install from requirements.txt
  pip3 install --upgrade pip
  pipe3 install fastapi uvicorn
  pip3 install -r requirements.txt

  # Start FastAPI with Uvicorn
  nohup uvicorn main:app --host 0.0.0.0 --port 8000 > output.log 2>&1 &
EOF





  tags = {
    Name = "TaskTrackerEC2"
  }
}

# Optional ALB (not strictly necessary for EC2 but included if desired)

resource "aws_lb" "app_alb" {
  name_prefix        = "tt-tg-"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  security_groups    = [aws_security_group.lb_sg.id]
}

resource "aws_lb_target_group" "app_tg" {
  name_prefix = "tt-tg-"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "app_attach" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app.id
  port             = 8000
}

