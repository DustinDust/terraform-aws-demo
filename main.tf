locals {
  public_vpc_prefix           = "${var.aws_vpc_name}-public"
  private_vpc_prefix          = "${var.aws_vpc_name}-private"
  default_security_group_name = "${var.aws_vpc_name}-sg"
  default_route_table_name    = "${var.aws_vpc_name}-rtb-default"
  alb_name                    = "${var.aws_vpc_name}-alb"
  database_subnet_group_name  = "${var.aws_rds_db_identifer}-subnet-group"
}

provider "aws" {
  region = var.aws_region
}

module "aws_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = var.aws_vpc_name
  cidr = var.aws_vpc_cidr
  azs  = var.aws_vpc_azs

  default_security_group_name  = local.default_security_group_name
  default_route_table_name     = local.default_route_table_name
  enable_nat_gateway           = var.aws_vpc_enable_nat_gateway
  create_database_subnet_group = true
  database_subnet_group_name   = local.database_subnet_group_name

  public_subnets   = var.aws_vpc_public_subnets
  private_subnets  = var.aws_vpc_private_subnets
  database_subnets = var.aws_vpc_database_subnets

  tags = var.aws_vpc_tags

  enable_dns_hostnames = true
  enable_dns_support   = true
}


module "aws_sg_instance" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"
  name    = "${local.default_security_group_name}-instance"
  vpc_id  = module.aws_vpc.vpc_id
  ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      description              = "HTTP from load balancer"
      source_security_group_id = module.aws_sg_loadbalancer.security_group_id
    },
    {
      rule                     = "https-443-tcp"
      description              = "HTTPs from load balancer"
      source_security_group_id = module.aws_sg_loadbalancer.security_group_id
    },
    {
      rule                     = "all-icmp"
      description              = "ICMP from load balancer"
      source_security_group_id = module.aws_sg_loadbalancer.security_group_id
    }
  ]
  egress_rules = ["all-all"]
}

module "aws_sg_loadbalancer" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"
  name    = "${local.default_security_group_name}-loadbalancer"
  vpc_id  = module.aws_vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "all-icmp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_rules = ["all-all"]
}

module "aws_sg_rds" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"
  name    = "${local.default_security_group_name}-rds"
  vpc_id  = module.aws_vpc.vpc_id
  ingress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      source_security_group_id = module.aws_sg_instance.security_group_id
    }
  ]
}

module "aws_rds" {
  source     = "terraform-aws-modules/rds/aws"
  version    = "5.6.0"
  identifier = var.aws_rds_db_identifer

  engine                = var.aws_rds_db_engine
  engine_version        = var.aws_rds_db_engine_version
  family                = var.aws_rds_db_family
  major_engine_version  = var.aws_rds_db_major_engine_version
  instance_class        = var.aws_rds_db_instance_class
  allocated_storage     = var.aws_rds_db_allocated_storage
  max_allocated_storage = var.aws_rds_db_max_allocated_storage

  db_subnet_group_name   = module.aws_vpc.database_subnet_group
  vpc_security_group_ids = [module.aws_sg_rds.security_group_id]

  db_name  = var.aws_rds_db_name
  username = var.aws_rds_db_username
  port     = var.aws_rds_db_port
  password = var.aws_rds_default_master_password

  multi_az = var.aws_rds_db_multi_az

  skip_final_snapshot = var.aws_rds_skip_final_snapshot
  deletion_protection = var.aws_rds_delete_protection

  # performance_insights_enabled          = false
  # performance_insights_retention_period = 7
  # create_monitoring_role                = false
  # monitoring_interval = 60
  # monitoring_role_arn = data.aws_iam_role.aws_rds_monitoring_role.arn
  storage_encrypted = false


  # enabled_cloudwatch_logs_exports = var.aws_rds_enabled_cloudwatch_logs_export
  # create_cloudwatch_log_group     = true
  maintenance_window = var.aws_rds_maintenance_window
  backup_window      = var.aws_rds_backup_window
}

module "aws_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.5.0"

  name               = local.alb_name
  load_balancer_type = "application"
  vpc_id             = module.aws_vpc.vpc_id
  subnets            = module.aws_vpc.public_subnets
  security_groups    = [module.aws_sg_loadbalancer.security_group_id]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]
  http_tcp_listener_rules = [
    {
      http_tcp_listener_index = 0
      actions = [{
        type         = "fixed-response"
        content_type = "text/plain"
        status_code  = 404
        message_body = "Not found, custom message"
      }]
      conditions = [
        {
          path_patterns = ["/error"]
        }
      ]
    }
  ]
  target_groups = [
    {
      name_prefix                       = "htg1"
      backend_protocol                  = "HTTP"
      backend_port                      = 80
      target_type                       = "instance"
      deregistration_delay              = 10
      load_balancing_cross_zone_enabled = true
      health_check = {
        enabled  = true
        protocol = "HTTP"
        matcher  = "200-399"
        port     = "traffic-port"
      }
      protocol_version = "HTTP1"
      targets = {
        for i, v in zipmap(module.aws_vpc.azs, module.aws_vpc.private_subnets) :
        "instance-${i}" => {
          target_id = module.aws_ec2_instance[i].id
          port      = 80
        }
      }
    }
  ]
}

module "aws_s3_log_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "3.8.2"
  bucket        = "${var.aws_s3_bucket_name}-log"
  acl           = "log-delivery-write"
  force_destroy = true

  attach_elb_log_delivery_policy        = true
  attach_lb_log_delivery_policy         = true
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
}

module "aws_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.8.2"

  bucket              = var.aws_s3_bucket_name
  force_destroy       = true
  acceleration_status = "Suspended"
  request_payer       = "BucketOwner"
  object_lock_enabled = true
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode = "GOVERNANCE"
        days = 1
      }
    }
  }

  versioning = {
    status     = true
    mfa_delete = false

  }

  acl = "public-read"
  logging = {
    target_bucket = module.aws_s3_log_bucket.s3_bucket_id
    target_prefix = "log/"
  }
  website = {
    index_document = "index.html"
    error_document = "error.html"

    # routing rules for fun
    routing_rules = [{
      condition = {
        key_prefix_equals = "docs/"
      },
      redirect = {
        replace_key_prefix_with = "documents/"
      }
      }, {
      condition = {
        http_error_code_returned_equals = 404
        key_prefix_equals               = "archive/"
      },
      redirect = {
        host_name          = "archive.myhost.com"
        http_redirect_code = 301
        protocol           = "https"
        replace_key_with   = "not_found.html"
      }
    }]
  }
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.aws_s3_sse_kms_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  # example cors
  cors_rule = [
    {
      allowed_methods = ["PUT", "GET", "POST"]
      allowed_origins = ["https://example.com"]
      allowed_headers = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]
}


module "aws_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.3.0"
  # EC2 deployed to private subnets
  for_each = zipmap(module.aws_vpc.azs, module.aws_vpc.private_subnets)

  name                        = var.aws_ec2_name
  instance_type               = var.aws_ec2_instance_type
  ami                         = data.aws_ami.amazon_linux.id
  availability_zone           = each.key
  subnet_id                   = each.value
  vpc_security_group_ids      = [module.aws_sg_instance.security_group_id]
  associate_public_ip_address = var.aws_ec2_associate_public_ip_address
  key_name                    = aws_key_pair.aws_ec2_keypair.key_name
  user_data_base64            = var.aws_ec2_user_data != null ? (var.aws_ec2_user_data) : null
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.aws_vpc.vpc_id
}

data "aws_route_tables" "all" {
  vpc_id = module.aws_vpc.vpc_id
}



resource "aws_vpc_endpoint" "aws_vpc_s3_gateway_endpoint" {
  vpc_id            = module.aws_vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  # security_group_ids = [module.aws_sg_instance.security_group_id, module.aws_sg_loadbalancer.security_group_id]
  route_table_ids = data.aws_route_tables.all.ids
}

resource "aws_kms_key" "aws_s3_sse_kms_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}



####################################################
# - Create a key pair for SSH
####################################################
resource "aws_key_pair" "aws_ec2_keypair" {
  key_name   = "${var.aws_ec2_name}-keypair"
  public_key = tls_private_key.rs_keypair.public_key_openssh
}

resource "tls_private_key" "rs_keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "tf_key" {
  content  = tls_private_key.rs_keypair.private_key_pem
  filename = "${var.aws_ec2_name}_rsa.pem"
}


####################################################
# - Fetch AMI images
####################################################
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_iam_role" "aws_rds_monitoring_role" {
  name = "rds-monitoring-role"
}


