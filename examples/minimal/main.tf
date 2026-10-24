terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.0, < 7.0" }
  }
}

module "this" {
  source = "../../"

  name = "olensys-test-cognito"
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "cognito"
    owner        = "platform"
    cost_center  = "eng"
  }

  clients = {
    web = { callback_urls = ["https://app.example.com/callback"] }
  }
}
