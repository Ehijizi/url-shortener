terraform {
  backend "s3" {
    bucket         = "ehi-ci-cd-artifacts-718780249654"
    key            = "url-shortener/dev/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
