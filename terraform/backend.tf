# Terraform Backend Configuration
# State is stored in S3 with DynamoDB locking
#
# IMPORTANT: Before first run, create the S3 bucket and DynamoDB table:
#
# aws s3api create-bucket \
#   --bucket jira-terraform-state-<your-account-id> \
#   --region ap-southeast-1 \
#   --create-bucket-configuration LocationConstraint=ap-southeast-1
#
# aws s3api put-bucket-versioning \
#   --bucket jira-terraform-state-<your-account-id> \
#   --versioning-configuration Status=Enabled
#
# aws dynamodb create-table \
#   --table-name jira-terraform-locks \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST \
#   --region ap-southeast-1

terraform {
  backend "s3" {
    bucket         = "syncsoft-jira-terraform-state"
    key            = "jira/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "syncsoft-jira-terraform-locks"
  }
}
