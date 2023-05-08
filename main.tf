provider "aws" {
  region = "us-east-1"
  access_key = ""
  secret_key = ""
}

variable "name" {}
# Create an ECS cluster
resource "aws_ecs_cluster" "example_cluster" {
  name = "${var.name}"
}

terraform {
  backend "s3" {
    bucket = "abc-kishore"
    region = "us-east-1"
     dynamodb_table = "example-lock-table"
    #lock_timeout_seconds = 300
  }
}
