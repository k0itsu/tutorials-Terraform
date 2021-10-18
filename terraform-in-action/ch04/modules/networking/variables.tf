# These are the input variables for namespace, vpc, and sg
variable "namespace" {
  type = string
}

variable "vpc" {
  type = any
  # type constraint of 'any' means Terraform will skip type checking
  # try to use this only for passing data between modules
}

variable "sg" {
  type = any
}