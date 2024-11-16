variable "aws_profile" {
  description = "AWS profile in the local config file from the machine where terraform will be executed"
  type        = string
}

variable "region" {
  description = "AWS region used to manage resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment to manage in AWS"
  type        = string
  default     = "test"
}

variable "name" {
  description = "Base name for this set of terraform resources"
  type        = string
  default     = "containerised-deployments-%s"
}

variable "description" {
  description = "Use of these terraform resources"
  type        = string
  default     = "Test environment for seminar in Auckland"
}

variable "db_name" {
  description = "The name of the database to be created."
  type        = string
  default     = "US_Elections_2018"
}

variable "db_user" {
  description = "The username of the database to be created."
  type        = string
  default     = "epidb"
}

variable "db_port" {
  description = "The port of the database to be created."
  type        = number
  default     = 5432
}
