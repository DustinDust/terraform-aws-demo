aws_region                 = "ap-southeast-1"
aws_vpc_name               = "CloudChaser-demo"
aws_vpc_cidr               = "10.0.0.0/16"
aws_vpc_azs                = ["ap-southeast-1a", "ap-southeast-1b"]
aws_vpc_public_subnets     = ["10.0.0.0/20", "10.0.16.0/20"]
aws_vpc_private_subnets    = ["10.0.128.0/20", "10.0.144.0/20"]
aws_vpc_enable_nat_gateway = "false"
aws_vpc_tags = {
  Terraform   = "true"
  Environment = "dev"
}
aws_ec2_name                        = "cloudchaser_instance"
aws_ec2_instance_type               = "t2.micro"
aws_ec2_associate_public_ip_address = "true"
