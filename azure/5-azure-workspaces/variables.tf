variable "resource_group_name" {
    type = string
    description = "RG in azure"
}

variable "virtual_network_name" {
    type = string
    description = "VG in azure"
}
variable "subnet_name" {
    type = string
    description = "subnet in azure"
}
variable "network_interface_name" {
    type = string
    description = "network interface name in azure"
}
variable "public_ip_name" {
    type = string
    description = "Public IP in azure"
}
variable "virtual_machine_name" {
    type = string
    description = "Virtual machine in azure"
}
variable "computer_names" {
  description = "Names of the computers for each environment"
  type        = list(string)
  default     = ["dev-env", "int-env", "prod-env"]
}
