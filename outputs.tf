output "id" {
  description = "ID of the user pool. Null when create is false."
  value       = try(aws_cognito_user_pool.this[0].id, null)
}

output "name" {
  description = "Name of the user pool. Null when create is false."
  value       = var.create ? var.name : null
}

output "arn" {
  description = "ARN of the user pool. Null when create is false."
  value       = try(aws_cognito_user_pool.this[0].arn, null)
}

output "endpoint" {
  description = "Endpoint of the user pool (issuer host and path, without scheme). Null when create is false."
  value       = try(aws_cognito_user_pool.this[0].endpoint, null)
}

output "domain" {
  description = "Hosted UI domain string (prefix or custom domain), or null when no domain is configured or create is false."
  value       = try(aws_cognito_user_pool_domain.this[0].domain, null)

  precondition {
    condition     = var.domain == null ? true : (var.domain.custom_domain == null || var.domain.certificate_arn != null)
    error_message = "domain.certificate_arn is required when domain.custom_domain is set."
  }
}

output "client_ids" {
  description = "Map of client name to app client ID. Null when create is false."
  value       = var.create ? { for k, c in aws_cognito_user_pool_client.this : k => c.id } : null
}

output "client_secrets" {
  description = "Map of client name to app client secret (empty string for clients without a secret). Null when create is false."
  value       = var.create ? { for k, c in aws_cognito_user_pool_client.this : k => c.client_secret } : null
  sensitive   = true
}

output "mfa_configuration" {
  description = "Effective MFA mode of the user pool. Null when create is false."
  value       = try(aws_cognito_user_pool.this[0].mfa_configuration, null)
}

output "deletion_protection" {
  description = "Effective deletion protection of the user pool (ACTIVE in prod). Null when create is false."
  value       = try(aws_cognito_user_pool.this[0].deletion_protection, null)
}

output "tags" {
  description = "Tags applied to every taggable resource, with context.extra_tags merged in. Null when create is false."
  value       = var.create ? local.tags : null
}
