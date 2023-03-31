variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "github_token" {
  type      = string
  sensitive = true
}