resource "aws_dynamodb_table" "url_shortener" {
  name         = "url-shortener-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "short_code"

  attribute {
    name = "short_code"
    type = "S"
  }

  tags = {
    Name        = "url-shortener-table"
    Environment = "production"
  }
}