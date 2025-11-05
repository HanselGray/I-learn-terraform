module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-terraform-vpc"
  cidr = "10.10.0.0/16"

  azs             = ["ap-southeast-1a", "ap-southeast-1b"]
  private_subnets = ["10.10.11.0/24", "10.10.12.0/24"]
  public_subnets  = ["10.10.1.0/24", "10.10.2.0/24"]

  # GATEWAYS
  create_igw         = true
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = true

  # FLOW_LOGS
  create_flow_log_cloudwatch_iam_role = true
  create_flow_log_cloudwatch_log_group = true
  enable_flow_log = true
  vpc_flow_log_iam_policy_name = "terraform-vpc-flow-log-to-cloudwatch"
  vpc_flow_log_iam_role_name = "terraform-vpc-flow-log-role"
  flow_log_max_aggregation_interval = 60 #seconds
  vpc_flow_log_tags = {
    Terraform = "true"
    Environment = "lab" 
  }

  tags = {
    Terraform   = "true"
    Environment = "lab"
  }
}

# ------------------- VPC ENDPOINTS ------------------- 

resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.ap-southeast-1.ssm"
  vpc_endpoint_type = "Interface"
  ip_address_type   = "ipv4"

  subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1],
  ]

  security_group_ids = [
    module.vpc_endpoints_secg.security_group_id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm_messages_endpoint" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.ap-southeast-1.ssmmessages"
  vpc_endpoint_type = "Interface"
  ip_address_type   = "ipv4"

  subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1],

  ]

  security_group_ids = [
    module.vpc_endpoints_secg.security_group_id,
  ]


  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.ap-southeast-1.ec2messages"
  vpc_endpoint_type = "Interface"
  ip_address_type   = "ipv4"

  subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1],
  ]

  security_group_ids = [
    module.vpc_endpoints_secg.security_group_id,
  ]

  private_dns_enabled = true
}



