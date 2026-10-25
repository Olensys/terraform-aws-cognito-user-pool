# terraform-aws-cognito-user-pool

Cognito user pool with hardened defaults, app clients, hosted UI domain, federated identity providers and Lambda triggers

## Opinions

- Deletion protection is `ACTIVE` when `context.environment == "prod"`, otherwise `INACTIVE`.
- Threat protection is `OFF` and the plan is `ESSENTIALS` by default; opt into `AUDIT`/`ENFORCED` together with `PLUS`.
- Sign-in is by email: `username_attributes = ["email"]`, `auto_verified_attributes = ["email"]`.
- Account recovery is verified email only (priority 1).
- MFA defaults to `OPTIONAL`; when not `OFF`, software token (TOTP) MFA is enabled. SMS MFA is not supported in v1. `ON` breaks passwordless and social flows, so it is opt-in.
- Email sending uses the Cognito default sender unless `email.ses_source_arn` is set (then `DEVELOPER` with SES).
- Password policy defaults: minimum length 12, lowercase, uppercase, numbers and symbols required, temporary passwords valid 7 days.
- App clients always have token revocation enabled and `prevent_user_existence_errors = "ENABLED"`; they allow OAuth flows on the user pool client, support `COGNITO` plus every configured identity provider, and use token validity units minutes (access, id) and days (refresh).
- Custom attributes of type String get string constraints min 0, max 2048. Schema cannot be altered in place after creation.
- Identity provider types supported in v1: Google, Facebook, LoginWithAmazon. `identity_providers` is sensitive.
- Each `lambda_triggers` entry also creates an `aws_lambda_permission` for `cognito-idp.amazonaws.com` scoped to the pool.
- A custom domain requires `certificate_arn` (ACM certificate in us-east-1); enforced by a precondition on the `domain` output.

## Usage

```hcl
module "naming" {
  source  = "git::https://github.com/Olensys/terraform-null-naming.git?ref=v1.0.1"
  context = var.context
}

module "cognito_user_pool" {
  source  = "git::https://github.com/Olensys/terraform-aws-cognito-user-pool.git?ref=v1.0.1"
  name    = module.naming.name
  context = var.context

  tags = module.naming.tags
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cognito_identity_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_provider) | resource |
| [aws_cognito_user_pool.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |
| [aws_cognito_user_pool_domain.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain) | resource |
| [aws_lambda_permission.triggers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_context"></a> [context](#input\_context) | Deployment context used for naming, tagging and environment-dependent defaults. | <pre>object({<br/>    organization = string<br/>    environment  = string<br/>    application  = string<br/>    component    = optional(string)<br/>    owner        = string<br/>    cost_center  = string<br/>    extra_tags   = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Resource name. Lowercase letters, digits and hyphens. | `string` | n/a | yes |
| <a name="input_advanced_security"></a> [advanced\_security](#input\_advanced\_security) | Cognito threat protection mode. AUDIT and ENFORCED require user\_pool\_tier = PLUS and are billed at the Plus rate. | `string` | `"OFF"` | no |
| <a name="input_clients"></a> [clients](#input\_clients) | App clients keyed by name. oauth\_flows may contain code, implicit, client\_credentials. | <pre>map(object({<br/>    callback_urls   = list(string)<br/>    logout_urls     = optional(list(string), [])<br/>    generate_secret = optional(bool, false)<br/>    oauth_flows     = optional(list(string), ["code"])<br/>    oauth_scopes    = optional(list(string), ["openid", "email", "profile"])<br/>    token_validity = optional(object({<br/>      access_min   = optional(number, 60)<br/>      id_min       = optional(number, 60)<br/>      refresh_days = optional(number, 30)<br/>    }), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to create any resources. Set false to create nothing. | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Hosted UI domain. Set exactly one of prefix (Cognito-hosted domain prefix) or custom\_domain (requires certificate\_arn, an ACM certificate in us-east-1). Null creates no domain. | <pre>object({<br/>    prefix          = optional(string)<br/>    custom_domain   = optional(string)<br/>    certificate_arn = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_email"></a> [email](#input\_email) | Email sending configuration. Null uses the Cognito default sender. Set ses\_source\_arn to send through SES (from and reply\_to are then applied). | <pre>object({<br/>    from           = optional(string)<br/>    ses_source_arn = optional(string)<br/>    reply_to       = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_identity_providers"></a> [identity\_providers](#input\_identity\_providers) | Federated identity providers keyed by provider name. type is one of Google, Facebook, LoginWithAmazon. scopes become authorize\_scopes. Sensitive because of client\_secret. | <pre>map(object({<br/>    type              = string<br/>    client_id         = string<br/>    client_secret     = string<br/>    scopes            = optional(list(string))<br/>    attribute_mapping = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_lambda_triggers"></a> [lambda\_triggers](#input\_lambda\_triggers) | Lambda triggers: Cognito trigger name => function ARN. The module grants cognito-idp.amazonaws.com invoke permission on each. | `map(string)` | `{}` | no |
| <a name="input_mfa"></a> [mfa](#input\_mfa) | MFA mode: OFF, OPTIONAL or ON. When not OFF, software token (TOTP) MFA is enabled. SMS MFA is not supported. | `string` | `"OPTIONAL"` | no |
| <a name="input_password_policy"></a> [password\_policy](#input\_password\_policy) | Password policy. Defaults: minimum length 12, all four character classes required, temporary passwords valid 7 days. | <pre>object({<br/>    minimum_length                   = optional(number, 12)<br/>    require_lowercase                = optional(bool, true)<br/>    require_uppercase                = optional(bool, true)<br/>    require_numbers                  = optional(bool, true)<br/>    require_symbols                  = optional(bool, true)<br/>    temporary_password_validity_days = optional(number, 7)<br/>  })</pre> | `{}` | no |
| <a name="input_schema"></a> [schema](#input\_schema) | Custom user pool attributes. type is one of String, Number, DateTime, Boolean. Schema cannot be changed in place after creation. | <pre>list(object({<br/>    name     = string<br/>    type     = string<br/>    required = optional(bool, false)<br/>    mutable  = optional(bool, true)<br/>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags merged onto every taggable resource, applied last. | `map(string)` | `{}` | no |
| <a name="input_user_pool_tier"></a> [user\_pool\_tier](#input\_user\_pool\_tier) | Cognito feature plan: LITE, ESSENTIALS or PLUS. | `string` | `"ESSENTIALS"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the user pool. Null when create is false. |
| <a name="output_client_ids"></a> [client\_ids](#output\_client\_ids) | Map of client name to app client ID. Null when create is false. |
| <a name="output_client_secrets"></a> [client\_secrets](#output\_client\_secrets) | Map of client name to app client secret (empty string for clients without a secret). Null when create is false. |
| <a name="output_deletion_protection"></a> [deletion\_protection](#output\_deletion\_protection) | Effective deletion protection of the user pool (ACTIVE in prod). Null when create is false. |
| <a name="output_domain"></a> [domain](#output\_domain) | Hosted UI domain string (prefix or custom domain), or null when no domain is configured or create is false. |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Endpoint of the user pool (issuer host and path, without scheme). Null when create is false. |
| <a name="output_id"></a> [id](#output\_id) | ID of the user pool. Null when create is false. |
| <a name="output_mfa_configuration"></a> [mfa\_configuration](#output\_mfa\_configuration) | Effective MFA mode of the user pool. Null when create is false. |
| <a name="output_name"></a> [name](#output\_name) | Name of the user pool. Null when create is false. |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags applied to every taggable resource, with context.extra\_tags merged in. Null when create is false. |
<!-- END_TF_DOCS -->
