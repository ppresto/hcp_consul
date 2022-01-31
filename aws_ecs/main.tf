locals {
  name        = "presto_ecs"
  environment = "dev"

  # This is the convention we use to know what belongs to each other
  ec2_resources_name = "${local.name}_${local.environment}"
}

data "terraform_remote_state" "aws_network" {
  backend = "remote"
  config = {
    organization = "presto-projects"
    workspaces = {
      name = "aws_network"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_security_group" "vpc_default" {
  name   = "default"
  vpc_id = data.terraform_remote_state.aws_network.outputs.vpc_id
}

#----- ECS --------
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "3.4.1"

  name               = local.name
  container_insights = true

  capacity_providers = ["FARGATE", "FARGATE_SPOT", aws_ecs_capacity_provider.prov1.name]

  default_capacity_provider_strategy = [{
    capacity_provider = "FARGATE" # aws_ecs_capacity_provider.prov1.name # "FARGATE_SPOT"
    weight            = "1"
  }]

  tags = {
    Environment = local.environment
  }
}

module "ec2_profile" {
  source  = "terraform-aws-modules/ecs/aws//modules/ecs-instance-profile"
  version = "3.4.1"

  name = local.name

  tags = {
    Environment = local.environment
  }
}

resource "aws_ecs_capacity_provider" "prov1" {
  name = "${local.name}_prov1"

  auto_scaling_group_provider {
    auto_scaling_group_arn = module.asg.autoscaling_group_arn
  }

}

#----- ECS  Services--------
#module "hello_world" {
#  source = "./service-hello-world"
#  cluster_id = module.ecs.ecs_cluster_id
#  target_subnets = data.terraform_remote_state.aws_network.outputs.vpc_private_subnets
#}

module "fake-service" {
  source            = "./service-client-example"
  name              = "fake-service"
  target_subnets    = data.terraform_remote_state.aws_network.outputs.vpc_private_subnets
  alb_subnets       = data.terraform_remote_state.aws_network.outputs.vpc_public_subnets
  vpc_id            = data.terraform_remote_state.aws_network.outputs.vpc_id
  security_group_id = data.aws_security_group.vpc_default.id
  cluster_id        = module.ecs.ecs_cluster_id
  region            = var.region
}

#----- ECS  Resources--------

#For now we only use the AWS ECS optimized ami <https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html>
data "aws_ami" "amazon_linux_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  name = local.ec2_resources_name

  # Launch configuration
  lc_name   = local.ec2_resources_name
  use_lc    = true
  create_lc = true

  image_id                  = data.aws_ami.amazon_linux_ecs.id
  instance_type             = "t2.micro"
  security_groups           = [data.terraform_remote_state.aws_network.outputs.vpc_default_security_group_id]
  iam_instance_profile_name = module.ec2_profile.iam_instance_profile_id
  user_data = templatefile("${path.module}/templates/user-data.sh", {
    cluster_name = local.name
  })

  # Auto scaling group
  vpc_zone_identifier       = data.terraform_remote_state.aws_network.outputs.vpc_private_subnets
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 2
  desired_capacity          = 0 # we don't need them for the example
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = local.environment
      propagate_at_launch = true
    },
    {
      key                 = "Cluster"
      value               = local.name
      propagate_at_launch = true
    },
  ]
}

###################
# Disabled cluster
###################

module "disabled_ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "3.4.1"

  create_ecs = false
}
