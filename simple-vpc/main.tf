provider "aws" {
  region = "ap-southeast-1"
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  owners = ["137112412989"] # Amazon
}


# ------------------- EC2 INSTANCES --------------------------

resource "aws_instance" "private-ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type


  vpc_security_group_ids = [module.private-subnet-secg.security_group_id]
  subnet_id              = module.vpc.private_subnets[0]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name
  # associate_public_ip_address = true
  # key_name               = aws_key_pair.ec2_private_subnet.id

  tags = {
    Name      = var.instance_name
    CreatedBy = var.created_by
  }
}

# resource "aws_instance" "public-ec2" {
#   ami           = data.aws_ami.amazon_linux.id
#   instance_type = var.instance_type


#   vpc_security_group_ids = [module.private-subnet-secg.security_group_id]
#   subnet_id              = module.vpc.public_subnets[0]
#   iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name
#   # key_name               = aws_key_pair.ec2_private_subnet.id

#   tags = {
#     Name      = var.instance_name
#     CreatedBy = var.created_by
#   }
# }

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "EC2-SessionManager-Profile"
  role = aws_iam_role.ec2_ssm.name
}

# resource "aws_key_pair" "ec2_private_subnet" {
#   key_name   = "ec2-private-subnet-key"
#   public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK18BDVeibL3Y0ICO0wsJNwUiPycaH6OroCDzLzxdl5V huypdg@DESKTOP-61GFAV3"
# }


# -------------- VPC-ENDPOINTS ------------------

resource "aws_ec2_instance_connect_endpoint" "eic-private-subnet-01" {
  subnet_id          = module.vpc.private_subnets[0]
  security_group_ids = [module.eic-endpoints-secg.security_group_id]
  depends_on         = [module.vpc]

  tags = {
    Name      = "eic-private-subnet-01"
    CreatedBy = var.created_by
  }
}