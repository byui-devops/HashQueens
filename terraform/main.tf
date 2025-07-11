provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              docker run -d -p 80:5000 yourdockerhubusername/group-c-app
            EOF

  tags = {
    Name = "Group-C-EC2"
  }
}

