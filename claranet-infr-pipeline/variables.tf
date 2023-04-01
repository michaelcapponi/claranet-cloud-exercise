variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "owner" {
  type      = string
  sensitive = true
  default = "michaelcapponi"
}

variable "repository" {
  type      = string
  sensitive = true
  default = "claranet-cloud-exercise"
}

variable "branch" {
  type      = string
  sensitive = true
  default = "main"
}