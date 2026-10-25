mock_provider "aws" {
  mock_resource "aws_cognito_user_pool" {
    defaults = {
      arn = "arn:aws:cognito-idp:us-east-1:111122223333:userpool/us-east-1_mock"
    }
  }
}

variables {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
  name = "example"
}

run "test_mfa_optional_default" {
  command = plan

  assert {
    condition     = aws_cognito_user_pool.this[0].mfa_configuration == "OPTIONAL"
    error_message = "mfa must default to OPTIONAL."
  }

  assert {
    condition     = output.mfa_configuration == "OPTIONAL"
    error_message = "mfa_configuration output must be OPTIONAL by default."
  }
}

run "test_mfa_validation" {
  command = plan

  variables {
    mfa = "SOMETIMES"
  }

  expect_failures = [var.mfa]
}

run "test_clients_created_per_key" {
  command = plan

  variables {
    clients = {
      web = { callback_urls = ["https://app.example.com/cb"] }
      cli = { callback_urls = ["http://localhost:8080/cb"], generate_secret = true }
    }
  }

  assert {
    condition     = length(aws_cognito_user_pool_client.this) == 2
    error_message = "One client per key expected."
  }

  assert {
    condition     = aws_cognito_user_pool_client.this["web"].prevent_user_existence_errors == "ENABLED"
    error_message = "prevent_user_existence_errors must be ENABLED."
  }

  assert {
    condition     = aws_cognito_user_pool_client.this["web"].enable_token_revocation == true
    error_message = "enable_token_revocation must be true."
  }
}

run "test_client_secret_sensitive" {
  command = plan

  variables {
    clients = {
      web = { callback_urls = ["https://app.example.com/cb"], generate_secret = true }
    }
  }

  assert {
    condition     = issensitive(output.client_secrets)
    error_message = "client_secrets must be sensitive."
  }
}

run "test_lambda_permission_per_trigger" {
  command = plan

  variables {
    lambda_triggers = {
      pre_sign_up       = "arn:aws:lambda:us-east-1:111122223333:function:pre"
      post_confirmation = "arn:aws:lambda:us-east-1:111122223333:function:post"
    }
  }

  assert {
    condition     = length(aws_lambda_permission.triggers) == 2
    error_message = "One lambda permission per trigger expected."
  }

  assert {
    condition     = aws_lambda_permission.triggers["pre_sign_up"].principal == "cognito-idp.amazonaws.com"
    error_message = "Principal must be cognito-idp.amazonaws.com."
  }
}

run "test_deletion_protection_in_prod" {
  command = plan

  variables {
    context = {
      organization = "olensys"
      environment  = "prod"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
    }
  }

  assert {
    condition     = aws_cognito_user_pool.this[0].deletion_protection == "ACTIVE"
    error_message = "Deletion protection must be ACTIVE in prod."
  }

  assert {
    condition     = output.deletion_protection == "ACTIVE"
    error_message = "deletion_protection output must be ACTIVE in prod."
  }
}

run "test_deletion_protection_off_outside_prod" {
  command = plan

  assert {
    condition     = output.deletion_protection == "INACTIVE"
    error_message = "Deletion protection must be INACTIVE outside prod."
  }
}

run "test_create_false_plans_nothing" {
  command = plan

  variables {
    create = false
    clients = {
      web = { callback_urls = ["https://app.example.com/cb"] }
    }
    lambda_triggers = {
      pre_sign_up = "arn:aws:lambda:us-east-1:111122223333:function:pre"
    }
    domain = { prefix = "example" }
  }

  assert {
    condition     = length(aws_cognito_user_pool.this) == 0 && length(aws_cognito_user_pool_client.this) == 0 && length(aws_lambda_permission.triggers) == 0 && length(aws_cognito_user_pool_domain.this) == 0
    error_message = "No resources may be planned when create is false."
  }

  assert {
    condition     = output.id == null && output.name == null && output.arn == null && output.endpoint == null && output.domain == null && output.tags == null && output.mfa_configuration == null && output.deletion_protection == null
    error_message = "All scalar outputs must be null when create is false."
  }

  assert {
    condition     = nonsensitive(output.client_ids) == null && nonsensitive(output.client_secrets) == null
    error_message = "Map outputs must be null when create is false."
  }
}

run "test_tags_contract" {
  command = plan

  variables {
    tags = { Owner = "x" }
    context = {
      organization = "olensys"
      environment  = "test"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
      extra_tags   = { Owner = "y", Team = "z" }
    }
  }

  assert {
    condition     = output.tags.Owner == "x"
    error_message = "var.tags must win over context.extra_tags."
  }

  assert {
    condition     = output.tags.Team == "z"
    error_message = "context.extra_tags must be merged."
  }
}

run "test_domain_requires_one_of" {
  command = plan

  variables {
    domain = { prefix = "a", custom_domain = "auth.example.com", certificate_arn = "arn:aws:acm:us-east-1:111122223333:certificate/x" }
  }

  expect_failures = [var.domain]
}

run "test_domain_empty_object_rejected" {
  command = plan

  variables {
    domain = {}
  }

  expect_failures = [var.domain]
}

run "test_domain_prefix_creates_domain" {
  command = plan

  variables {
    domain = { prefix = "example-auth" }
  }

  assert {
    condition     = aws_cognito_user_pool_domain.this[0].domain == "example-auth"
    error_message = "Domain prefix must be used as the domain."
  }

  assert {
    condition     = output.domain == "example-auth"
    error_message = "domain output must be the prefix."
  }
}

run "test_custom_domain_needs_certificate" {
  command = plan

  variables {
    domain = { custom_domain = "auth.example.com" }
  }

  expect_failures = [output.domain]
}

run "test_trigger_name_validation" {
  command = plan

  variables {
    lambda_triggers = { not_a_trigger = "arn:aws:lambda:us-east-1:111122223333:function:x" }
  }

  expect_failures = [var.lambda_triggers]
}

run "test_name_length_validation" {
  command = plan

  variables {
    name = join("", [for i in range(129) : "a"])
  }

  expect_failures = [var.name]
}

run "test_tier_default_essentials" {
  command = plan
  assert {
    condition     = aws_cognito_user_pool.this[0].user_pool_tier == "ESSENTIALS"
    error_message = "user_pool_tier must default to ESSENTIALS."
  }
  assert {
    condition     = aws_cognito_user_pool.this[0].user_pool_add_ons[0].advanced_security_mode == "OFF"
    error_message = "advanced_security must default to OFF."
  }
}

run "test_advanced_security_with_plus" {
  command = plan
  variables {
    advanced_security = "ENFORCED"
    user_pool_tier    = "PLUS"
  }
  assert {
    condition     = aws_cognito_user_pool.this[0].user_pool_add_ons[0].advanced_security_mode == "ENFORCED" && aws_cognito_user_pool.this[0].user_pool_tier == "PLUS"
    error_message = "ENFORCED on PLUS must be passed through."
  }
}

run "test_advanced_security_requires_plus" {
  command = plan
  variables { advanced_security = "AUDIT" }
  expect_failures = [output.id]
}

run "test_advanced_security_validation" {
  command = plan
  variables { advanced_security = "ON" }
  expect_failures = [var.advanced_security]
}

run "test_tier_validation" {
  command = plan
  variables { user_pool_tier = "PREMIUM" }
  expect_failures = [var.user_pool_tier]
}
