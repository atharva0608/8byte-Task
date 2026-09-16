terraform {
  backend "s3" {
    bucket       = "8byte-tfstate-759655305018"
    key          = "infra/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
