terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
   backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "allocnow-demo/ecs-web-app.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    use_lockfile   = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "ecs_web_service" {
  source = "./modules/ecs_web_service"

  vpc_id          = var.vpc_id
  alb_subnets     = var.alb_subnets
  private_subnets = var.private_subnets

  frontend_image  = var.frontend_image
  backend_image   = var.backend_image
}


