variable "aws_region" {
  description = "Region of the AWS"
  type        = string
  default     = "ap-southeast-1"
}

############################################
# EC2 var
############################################
variable "aws_ec2_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "my-instance"
}

variable "aws_ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "aws_ec2_associate_public_ip_address" {
  description = "Associate a public IP address with new EC2 instance"
  type        = bool
  default     = true
}

variable "aws_ec2_user_data" {
  description = "EC2 instance user data"
  type        = string
  default     = null
}


############################################
# VPC var
############################################
variable "aws_vpc_name" {
  description = "Name of VPC"
  type        = string
  default     = "my-vpc"
}

variable "aws_vpc_cidr" {
  description = "CIDR of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_vpc_azs" {
  description = "Availability zones for VPC"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "aws_vpc_public_subnets" {
  description = "Public subnets for VPC"
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.16.0/20"]
}


variable "aws_vpc_private_subnets" {
  description = "Private subnets for VPC"
  type        = list(string)
  default     = ["10.0.128.0/20", "10.0.144.0/20"]
}

variable "aws_vpc_database_subnets" {
  description = "Database subnet for VPC"
  type        = list(string)
  default     = ["10.0.160.0/20", "10.0.176.0/20"]
}

variable "aws_vpc_enable_nat_gateway" {
  description = "Enable NAT gateway for VPC"
  type        = bool
  default     = false
}

variable "aws_vpc_tags" {
  description = "Tags to apply to resources created by VPC module"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
  }
}


############################################
# RDS var
############################################
variable "aws_rds_db_identifer" {
  description = "Identifier of RDS database"
  type        = string
  default     = "my-db"
}

variable "aws_rds_db_engine" {
  description = "Engine of RDS database"
  type        = string
  default     = "mysql"
}

variable "aws_rds_db_engine_version" {
  description = "Version of DB engine"
  type        = string
  default     = "8.0"
}
variable "aws_rds_db_family" {
  description = "Family of Database parameter group"
  type        = string
  default     = "mysql8.0"
}

variable "aws_rds_db_major_engine_version" {
  description = "Major engine version of Database option group"
  type        = string
  default     = "8.0"
}

variable "aws_rds_db_instance_class" {
  description = "Class of DB instance"
  type        = string
  default     = "db.t2.micro"
}

variable "aws_rds_db_allocated_storage" {
  description = "Allocated storage for RDS Database"
  type        = number
  default     = 10
}

variable "aws_rds_db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS Database"
  type        = number
  default     = 100
}

variable "aws_rds_db_multi_az" {
  description = "Enable Multi AZ for RDS database"
  type        = bool
  default     = false
}

variable "aws_rds_db_name" {
  description = "Name of the Database"
  type        = string
  default     = "rootdb"
}

variable "aws_rds_db_username" {
  description = "Root username of the RDS database"
  type        = string
  default     = "admin"
}

variable "aws_rds_db_port" {
  description = "Exposed port of the RDS database"
  type        = number
  default     = 3306 # mysql default port
}

variable "aws_rds_skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = true
}

variable "aws_rds_delete_protection" {
  description = "RDS Delete protection"
  type        = bool
  default     = false
}
variable "aws_rds_enabled_cloudwatch_logs_export" {
  description = "Which cloudwatch logs to export"
  type        = list(string)
  default     = ["general"]
}
variable "aws_rds_maintenance_window" {
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'"
  type        = string
  default     = "Mon:00:00-Mon:03:00"

}

variable "aws_rds_backup_window" {
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled"
  type        = string
  default     = "09:46-10:16"
}

variable "aws_rds_default_master_password" {
  description = "Default master password for AWS"
  type        = string
  default     = "123123123"
}

variable "aws_s3_bucket_name" {
  description = "Bucket name"
  type        = string
  default     = "cloudchaser-bucket"
}
