locals{
    name = "sakamoto-learn"

    domain = "${local.name}.sandbox.ctag-timemachine.xyz"

    availability_zones = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]

    vpc_cidr = "10.0.0.0/16"

    db_name     = "main"
    db_user     = "db_user"
    db_password = "db_password"

    #env = "stg"
    env = "prd"

    is_staging_and_staging_off = local.env == "stg" && !var.staging_on

    aws_account_id = {
    stg = "259798983143"
    prd = "259798983143"
  }
}

variable "staging_on" {
  type    = bool
  default = true
}