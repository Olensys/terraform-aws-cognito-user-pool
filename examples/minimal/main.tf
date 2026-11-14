terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.0, < 7.0" }
  }
}

module "naming" {
  source = "git::https://github.com/Olensys/terraform-null-naming.git?ref=v1.0.1"

  context = local.context
}

locals {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "cognito"
    owner        = "platform"
    cost_center  = "eng"
  }
}

module "this" {
  source = "../../"

  name    = module.naming.name
  context = local.context
  tags    = module.naming.tags

  clients = {
    web = { callback_urls = ["https://app.example.com/callback"] }
  }
}
