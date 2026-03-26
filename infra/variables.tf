variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "chat"
}

variable "eks_cluster_name" {
  description = "Name of the existing EKS cluster"
  type        = string
  default     = "url-shortener-cluster"
}

variable "vpc_name" {
  description = "Name of the existing VPC"
  type        = string
  default     = "url-shortener-vpc"
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
  default     = "placeholder.ap-northeast-1.elb.amazonaws.com"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "chat"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = "chatpassword123"
}
