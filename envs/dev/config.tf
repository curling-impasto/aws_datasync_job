provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Application = "sample"
      Customer    = "customer"
    }
  }
}

terraform {

  backend "s3" {
    bucket                 = "operations-tfstate"
    key                    = "aws-datasync-terraform.tfstate"
    region                 = "us-east-1"
    skip_region_validation = true
  }
}
