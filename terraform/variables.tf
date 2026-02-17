variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = map(string)
  default = {
    dev  = "10.0.0.0/16"
    prod = "10.1.0.0/16"
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = map(string)
  default = {
    dev  = "t2.micro"
    prod = "t3.small"
  }
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 5000
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
