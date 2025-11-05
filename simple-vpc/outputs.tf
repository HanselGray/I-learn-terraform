output "instance_hostname" {
  description = "Private DNS name of the EC2 instance."
  value       = aws_instance.private-ec2.private_dns
}

output "ami_info" {
  value = {
    id   = data.aws_ami.amazon_linux.id
    name = data.aws_ami.amazon_linux.name
  }
}

output "subnets_cidr" {
  value = [
    {
      private_subnets = module.vpc.private_subnets_cidr_blocks
      public_subnets = module.vpc.public_subnets_cidr_blocks
    },
  ]
}
