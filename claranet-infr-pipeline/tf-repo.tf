terraform {
  required_version = "~> 1.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.59"
    }
  }
  #backend "s3" {
  #  bucket  = <your-s3-bucket
  #  key     = "app/terraform.tfstate"
  #  region  = "eu-central-1"
  #}
}

data "aws_caller_identity" "current" {}

locals {
  account = data.aws_caller_identity.current.account_id
}

provider "aws" {
  region = var.region
}

# --------- CodeCommit Repo -----------
#resource "aws_codecommit_repository" "aws_infra_automation_repo" {
#  lifecycle {
#    prevent_destroy = false
#  }
#  repository_name = "aws_infra_automation"
#  description     = "Terraform IaC for deploying app resources infrastructure."
#}
