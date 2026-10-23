variable "name" {
  description = "Resource name. Lowercase letters, digits and hyphens."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,128}$", var.name))
    error_message = "name must match ^[a-z0-9-]{1,128}$."
  }
}

variable "context" {
  description = "Deployment context used for naming, tagging and environment-dependent defaults."
  type = object({
    organization = string
    environment  = string
    application  = string
    component    = optional(string)
    owner        = string
    cost_center  = string
    extra_tags   = optional(map(string), {})
  })
  validation {
    condition     = contains(["dev", "staging", "prod", "test", "shared"], var.context.environment)
    error_message = "context.environment must be one of dev, staging, prod, test, shared."
  }
}

variable "create" {
  description = "Whether to create any resources. Set false to create nothing."
  type        = bool
  default     = true
}

variable "domain" {
  description = "Hosted UI domain. Set exactly one of prefix (Cognito-hosted domain prefix) or custom_domain (requires certificate_arn, an ACM certificate in us-east-1). Null creates no domain."
  type = object({
    prefix          = optional(string)
    custom_domain   = optional(string)
    certificate_arn = optional(string)
  })
  default = null
  validation {
    condition     = var.domain == null ? true : (var.domain.prefix != null) != (var.domain.custom_domain != null)
    error_message = "domain must set exactly one of prefix or custom_domain."
  }
}

variable "password_policy" {
  description = "Password policy. Defaults: minimum length 12, all four character classes required, temporary passwords valid 7 days."
  type = object({
    minimum_length                   = optional(number, 12)
    require_lowercase                = optional(bool, true)
    require_uppercase                = optional(bool, true)
    require_numbers                  = optional(bool, true)
    require_symbols                  = optional(bool, true)
    temporary_password_validity_days = optional(number, 7)
  })
  default = {}
  validation {
    condition     = var.password_policy.minimum_length >= 6 && var.password_policy.minimum_length <= 99
    error_message = "password_policy.minimum_length must be between 6 and 99."
  }
  validation {
    condition     = var.password_policy.temporary_password_validity_days >= 0 && var.password_policy.temporary_password_validity_days <= 365
    error_message = "password_policy.temporary_password_validity_days must be between 0 and 365."
  }
}

variable "mfa" {
  description = "MFA mode: OFF, OPTIONAL or ON. When not OFF, software token (TOTP) MFA is enabled. SMS MFA is not supported."
  type        = string
  default     = "OPTIONAL"
  validation {
    condition     = contains(["OFF", "OPTIONAL", "ON"], var.mfa)
    error_message = "mfa must be one of OFF, OPTIONAL, ON."
  }
}

variable "email" {
  description = "Email sending configuration. Null uses the Cognito default sender. Set ses_source_arn to send through SES (from and reply_to are then applied)."
  type = object({
    from           = optional(string)
    ses_source_arn = optional(string)
    reply_to       = optional(string)
  })
  default = null
}

variable "schema" {
  description = "Custom user pool attributes. type is one of String, Number, DateTime, Boolean. Schema cannot be changed in place after creation."
  type = list(object({
    name     = string
    type     = string
    required = optional(bool, false)
    mutable  = optional(bool, true)
  }))
  default = []
  validation {
    condition     = alltrue([for s in var.schema : contains(["String", "Number", "DateTime", "Boolean"], s.type)])
    error_message = "schema[*].type must be one of String, Number, DateTime, Boolean."
  }
}

variable "clients" {
  description = "App clients keyed by name. oauth_flows may contain code, implicit, client_credentials."
  type = map(object({
    callback_urls   = list(string)
    logout_urls     = optional(list(string), [])
    generate_secret = optional(bool, false)
    oauth_flows     = optional(list(string), ["code"])
    oauth_scopes    = optional(list(string), ["openid", "email", "profile"])
    token_validity = optional(object({
      access_min   = optional(number, 60)
      id_min       = optional(number, 60)
      refresh_days = optional(number, 30)
    }), {})
  }))
  default = {}
  validation {
    condition     = alltrue([for c in var.clients : alltrue([for f in c.oauth_flows : contains(["code", "implicit", "client_credentials"], f)])])
    error_message = "clients[*].oauth_flows entries must be one of code, implicit, client_credentials."
  }
}

variable "identity_providers" {
  description = "Federated identity providers keyed by provider name. type is one of Google, Facebook, LoginWithAmazon. scopes become authorize_scopes. Sensitive because of client_secret."
  type = map(object({
    type              = string
    client_id         = string
    client_secret     = string
    scopes            = optional(list(string))
    attribute_mapping = optional(map(string), {})
  }))
  default   = {}
  sensitive = true
  validation {
    condition     = alltrue([for p in var.identity_providers : contains(["Google", "Facebook", "LoginWithAmazon"], p.type)])
    error_message = "identity_providers[*].type must be one of Google, Facebook, LoginWithAmazon."
  }
}

variable "lambda_triggers" {
  description = "Lambda triggers: Cognito trigger name => function ARN. The module grants cognito-idp.amazonaws.com invoke permission on each."
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([for k in keys(var.lambda_triggers) : contains([
      "pre_sign_up", "post_confirmation", "pre_authentication", "post_authentication", "custom_message",
      "define_auth_challenge", "create_auth_challenge", "verify_auth_challenge_response", "pre_token_generation", "user_migration",
    ], k)])
    error_message = "lambda_triggers keys must be valid Cognito trigger names (pre_sign_up, post_confirmation, pre_authentication, post_authentication, custom_message, define_auth_challenge, create_auth_challenge, verify_auth_challenge_response, pre_token_generation, user_migration)."
  }
}

variable "tags" {
  description = "Tags merged onto every taggable resource, applied last."
  type        = map(string)
  default     = {}
}
