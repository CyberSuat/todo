//variable "aws_secret_key" {}
//variable "aws_access_key" {}
variable "region" {}
variable "mykey" {}
variable "tags" {}
variable "k8stags" {}
variable "myami" {
  description = "2 AL-2023 ami"
}
variable "k8sami" {
  description = "1 ubuntu 20.04"
}
variable "instancetype" {}
variable "k8sinstancetype" {}
variable "num" {}