resource "aws_cognito_user_pool" "pool" {
  name = "mypool1"
}

resource "aws_cognito_user_pool_client" "client" {
  name = "client1"

  user_pool_id = aws_cognito_user_pool.pool.id

  explicit_auth_flows = ["ALLOW_USER_AUTH", "ALLOW_REFRESH_TOKEN_AUTH",  "ALLOW_USER_PASSWORD_AUTH"]

  generate_secret     = true
}
