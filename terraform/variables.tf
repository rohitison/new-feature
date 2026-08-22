variable "cluster_name" {
  description = "Kind cluster name"
  type        = string
  default     = "devops-interview"
}

variable "kind_config" {
  description = "Kind cluster configuration"
  type        = string
  default     = "../kind/cluster.yaml"
}