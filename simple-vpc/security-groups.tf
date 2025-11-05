module "public-subnet-secg" {
  source = "./shared-modules/security-group"

  name        = "terraform-vpc-public-subnet"
  description = "Allowing ICMP and SSH traffic in public subnet"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["all-icmp"]
  ingress_cidr_blocks = ["10.10.0.0/16"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow SSH into public ec2 instance"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  egress_rules = ["all-all"]
}

module "private-subnet-secg" {
  source = "./shared-modules/security-group"

  name        = "terraform-vpc-private-subnet"
  description = "Allowing ICMP and SSH traffic in public subnet"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["all-icmp"]
  ingress_cidr_blocks = ["10.10.0.0/16"]
  ingress_with_source_security_group_id = [
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      description              = "Allow SSH into private ec2 instance EC2 Instance Connect"
      source_security_group_id = module.eic-endpoints-secg.security_group_id
    },
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      description              = "Allow SSH into private ec2 instance via public instance"
      source_security_group_id = module.public-subnet-secg.security_group_id
    },
  ]
  egress_rules = ["all-all"]
}

module "eic-endpoints-secg" {
  source = "./shared-modules/security-group"

  name        = "terraform-vpc-eic-endpoints"
  description = "Allowing traffic into private subnet via EIC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow SSH into private ec2 instances"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_rules = ["all-all"]
}

module "vpc_endpoints_secg" {

  source = "./shared-modules/security-group"

  name        = "terraform-vpc-vpc-endpoints"
  description = "Allowing traffic into VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["https-443-tcp"]
  ingress_cidr_blocks = ["10.10.0.0/16"]

  egress_rules = ["all-all"]
}