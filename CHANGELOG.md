# Changelog

## [1.2.0](https://github.com/Olensys/terraform-aws-cognito-user-pool/compare/v1.1.0...v1.2.0) (2026-11-14)


### Features

* client explicit_auth_flows, schema length limits and attribute update verification ([#8](https://github.com/Olensys/terraform-aws-cognito-user-pool/issues/8)) ([34ae3f3](https://github.com/Olensys/terraform-aws-cognito-user-pool/commit/34ae3f37290d3c8179e47b54f4465197f0661752))


### Bug Fixes

* tag the minimal example's resources through the naming module ([#10](https://github.com/Olensys/terraform-aws-cognito-user-pool/issues/10)) ([838341a](https://github.com/Olensys/terraform-aws-cognito-user-pool/commit/838341acbc0a9ea9a6ab8497ad6b1909bd076e78))

## 1.2.0

### Bug Fixes

* identity providers no longer show a diff on every plan: the provider endpoints Cognito fills in after creation (`attributes_url`, `attributes_url_add_attributes`, `authorize_url`, `oidc_issuer`, `token_request_method`, `token_url`) are now ignored

## [1.1.0](https://github.com/Olensys/terraform-aws-cognito-user-pool/compare/v1.0.3...v1.1.0) (2026-10-25)


### Features

* advanced_security and user_pool_tier inputs ([#5](https://github.com/Olensys/terraform-aws-cognito-user-pool/issues/5)) ([22753e1](https://github.com/Olensys/terraform-aws-cognito-user-pool/commit/22753e1289bc7a793822b84b60337b95a2ef7680))

### Behaviour changes

New pools default to `user_pool_tier = "ESSENTIALS"` with `advanced_security = "OFF"`. Pools created by 1.0.x were implicitly PLUS with AUDIT and will show an in-place update; set `advanced_security = "AUDIT"` and `user_pool_tier = "PLUS"` to keep the previous behaviour.

## [1.0.3](https://github.com/Olensys/terraform-aws-cognito-user-pool/compare/v1.0.2...v1.0.3) (2026-10-24)


### Bug Fixes

* **examples:** unique application slug so concurrent integration runs do not collide ([#2](https://github.com/Olensys/terraform-aws-cognito-user-pool/issues/2)) ([20bcf81](https://github.com/Olensys/terraform-aws-cognito-user-pool/commit/20bcf8115d8a5b8b3eddf3a410afeb5dbc94bc55))

## [1.0.2](https://github.com/Olensys/terraform-aws-cognito-user-pool/compare/v1.0.1...v1.0.2) (2026-10-24)


### Bug Fixes

* run integration on change and weekly instead of nightly ([7e74329](https://github.com/Olensys/terraform-aws-cognito-user-pool/commit/7e7432997bb11a45aad1a0d846744869dfca81d3))

## 1.0.1

### Other

- pin docs lockfile setting and skip .terraform in trivy hook

## 1.0.0

- Cognito user pool with hardened defaults, app clients, hosted UI domain, federated identity providers and Lambda triggers.
