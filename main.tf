locals {
  tags = merge(var.context.extra_tags, var.tags)

  # Provider names are structural; only client_secret values are secret.
  idp_keys     = var.create ? toset(nonsensitive(keys(var.identity_providers))) : toset([])
  trigger_keys = var.create ? toset(keys(var.lambda_triggers)) : toset([])

  ses_arn = try(var.email.ses_source_arn, null)
}

resource "aws_cognito_user_pool" "this" {
  count = var.create ? 1 : 0

  name                     = var.name
  mfa_configuration        = var.mfa
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  deletion_protection      = var.context.environment == "prod" ? "ACTIVE" : "INACTIVE"
  tags                     = local.tags

  password_policy {
    minimum_length                   = var.password_policy.minimum_length
    require_lowercase                = var.password_policy.require_lowercase
    require_uppercase                = var.password_policy.require_uppercase
    require_numbers                  = var.password_policy.require_numbers
    require_symbols                  = var.password_policy.require_symbols
    temporary_password_validity_days = var.password_policy.temporary_password_validity_days
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  user_pool_add_ons {
    advanced_security_mode = "AUDIT"
  }

  email_configuration {
    email_sending_account  = local.ses_arn == null ? "COGNITO_DEFAULT" : "DEVELOPER"
    source_arn             = local.ses_arn
    from_email_address     = local.ses_arn == null ? null : try(var.email.from, null)
    reply_to_email_address = try(var.email.reply_to, null)
  }

  dynamic "software_token_mfa_configuration" {
    for_each = var.mfa == "OFF" ? [] : [1]
    content {
      enabled = true
    }
  }

  dynamic "schema" {
    for_each = var.schema
    content {
      name                = schema.value.name
      attribute_data_type = schema.value.type
      required            = schema.value.required
      mutable             = schema.value.mutable

      dynamic "string_attribute_constraints" {
        for_each = schema.value.type == "String" ? [1] : []
        content {
          min_length = 0
          max_length = 2048
        }
      }
    }
  }

  dynamic "lambda_config" {
    for_each = length(var.lambda_triggers) > 0 ? [1] : []
    content {
      pre_sign_up                    = lookup(var.lambda_triggers, "pre_sign_up", null)
      post_confirmation              = lookup(var.lambda_triggers, "post_confirmation", null)
      pre_authentication             = lookup(var.lambda_triggers, "pre_authentication", null)
      post_authentication            = lookup(var.lambda_triggers, "post_authentication", null)
      custom_message                 = lookup(var.lambda_triggers, "custom_message", null)
      define_auth_challenge          = lookup(var.lambda_triggers, "define_auth_challenge", null)
      create_auth_challenge          = lookup(var.lambda_triggers, "create_auth_challenge", null)
      verify_auth_challenge_response = lookup(var.lambda_triggers, "verify_auth_challenge_response", null)
      pre_token_generation           = lookup(var.lambda_triggers, "pre_token_generation", null)
      user_migration                 = lookup(var.lambda_triggers, "user_migration", null)
    }
  }
}

resource "aws_cognito_user_pool_domain" "this" {
  count = var.create && var.domain != null ? 1 : 0

  domain          = coalesce(var.domain.custom_domain, var.domain.prefix)
  certificate_arn = var.domain.custom_domain != null ? var.domain.certificate_arn : null
  user_pool_id    = aws_cognito_user_pool.this[0].id
}

resource "aws_cognito_identity_provider" "this" {
  for_each = local.idp_keys

  user_pool_id  = aws_cognito_user_pool.this[0].id
  provider_name = each.key
  provider_type = var.identity_providers[each.key].type
  provider_details = merge(
    {
      client_id     = var.identity_providers[each.key].client_id
      client_secret = var.identity_providers[each.key].client_secret
    },
    var.identity_providers[each.key].scopes == null ? {} : { authorize_scopes = join(" ", var.identity_providers[each.key].scopes) },
  )
  attribute_mapping = var.identity_providers[each.key].attribute_mapping
}

resource "aws_cognito_user_pool_client" "this" {
  for_each = var.create ? var.clients : {}

  name         = each.key
  user_pool_id = aws_cognito_user_pool.this[0].id

  generate_secret                      = each.value.generate_secret
  callback_urls                        = each.value.callback_urls
  logout_urls                          = each.value.logout_urls
  allowed_oauth_flows                  = each.value.oauth_flows
  allowed_oauth_scopes                 = each.value.oauth_scopes
  allowed_oauth_flows_user_pool_client = true
  supported_identity_providers         = concat(["COGNITO"], nonsensitive(keys(var.identity_providers)))
  enable_token_revocation              = true
  prevent_user_existence_errors        = "ENABLED"

  access_token_validity  = each.value.token_validity.access_min
  id_token_validity      = each.value.token_validity.id_min
  refresh_token_validity = each.value.token_validity.refresh_days

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  depends_on = [aws_cognito_identity_provider.this]
}

resource "aws_lambda_permission" "triggers" {
  for_each = local.trigger_keys

  statement_id  = "AllowCognito-${var.name}-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_triggers[each.key]
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.this[0].arn
}
