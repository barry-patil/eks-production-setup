variable "cluster_name"             { type = string }
variable "kubernetes_version"        { type = string; default = "1.29" }
variable "vpc_id"                    { type = string }
variable "public_subnet_ids"         { type = list(string) }
variable "private_subnet_ids"        { type = list(string) }
variable "cluster_role_arn"          { type = string }
variable "node_role_arn"             { type = string }
variable "ebs_csi_role_arn"          { type = string }
variable "app_node_instance_types"   { type = list(string); default = ["t3.large"] }
variable "app_node_desired"          { type = number; default = 2 }
variable "app_node_min"              { type = number; default = 1 }
variable "app_node_max"              { type = number; default = 10 }
variable "common_tags"               { type = map(string); default = {} }
