provider "aws" {
  region = "us-west-2"
}
resource "aws_instance" "app_server" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type = "t2.micro"
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "my_bucket" {
  bucket        = "${var.bucket_name}-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

user_data = <<-EOF
              #!/bin/bash
              docker run -d -p 80:5000 yourdockerhubusername/group-c-app
            EOF

  tags = {
    Name = "Group-C-EC2"
  }
}

