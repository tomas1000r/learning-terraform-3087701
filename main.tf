resource "aws_cognito_user_pool" "gohealth_consumers_cognito_user_pool" {
  name                = "qa-gohealth-consumers"
  deletion_protection = "INACTIVE"

  alias_attributes = ["phone_number", "email", "username"]

  schema {
    name                = "phone_number"
    attribute_data_type = "String"
    required            = true
    mutable             = false
  }

  password_policy {
    minimum_length                   = 8
    require_numbers                  = true
    require_uppercase                = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  mfa_configuration          = "ON"
  sms_authentication_message = "Your MyGoHealth MFA code is {####}"
  software_token_mfa_configuration {
    enabled = false
  }

  verification_message_template {
    sms_message = "Your MyGoHealth verification code is {####}"
  }

  sms_configuration {
    external_id    = "cognito-sms-role"
    sns_caller_arn = aws_iam_role.cognito_sns_role.arn
  }

  #
  # Business has requested that we allow users to reset password with a
  # verification code sent to their phone. This is a security concern, as MFA
  # codes are also sent to the phone. A bad actor with access to the user's
  # phone will always be able to reset password and login (completing MFA)
  # with only that device.
  #
  # Business prefers to not add another factor (email, for example), as
  # collecting and verifying this information is an step for users that is
  # likely to significantly reduce our adoption rate.
  #
  # InfoSec was consulted in this decision, and they approved of this
  # configuration. The reasoning being that if someone has access to the
  # user's actual device, they likely also already have access to the other
  # factor (logged in email on phone, for example).
  #
  # The option:
  #
  #   "SMS if available, otherwise email, and allow a user to reset their
  #     password via SMS if they are also using it for MFA"
  #
  # is not supported by the terraform provider or any available AWS SDK, and
  # AWS recommends against using it. A support case was opened to confirm:
  # https://support.console.aws.amazon.com/support/home?region=us-east-2#/case/?displayId=173860208800223
  #
  # We will set it manually in the UI. Omitting the following section will NOT
  # overwrite the manually selected value:
  #
  # account_recovery_setting {
  #   recovery_mechanism {
  #     name     = "verified_phone_number"
  #     priority = 1
  #   }
  #   recovery_mechanism {
  #     name     = "verified_email"
  #     priority = 2
  #   }
  # }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  username_configuration {
    case_sensitive = false
  }

  user_pool_add_ons {
    # OFF: Disable all advanced security features
    # AUDIT: Logs security events, but do not enforce blocks
    # ENFORCE: Enforces extra security measures
    advanced_security_mode = "AUDIT"
  }
}

resource "aws_cognito_user_pool_client" "gohealth_consumers_cognito_app_client" {
  name         = "qa-gohealth-consumers-app"
  user_pool_id = aws_cognito_user_pool.gohealth_consumers_cognito_user_pool.id

  supported_identity_providers = ["COGNITO"]
  explicit_auth_flows = [
    "ALLOW_USER_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  auth_session_validity = 15 # minutes, by default

  access_token_validity  = 5
  id_token_validity      = 5
  refresh_token_validity = 60

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "minutes"
  }

  prevent_user_existence_errors = "LEGACY" # show actual error messages

  enable_token_revocation = false
  generate_secret         = true

  read_attributes  = ["phone_number"]
  write_attributes = ["phone_number"]
}
