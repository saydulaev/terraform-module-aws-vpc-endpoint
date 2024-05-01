variable "vpc_id" {
  description = "The ID of the VPC in which the endpoint will be used."
  type        = string
}

variable "vpc_name" {
  description = "The name of VPC used for resource naming."
  type        = string
}

variable "security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface. Applicable for endpoints of type Interface"
  type        = list(string)
  default     = null
}

variable "route_table_ids" {
  description = "One or more route table IDs. Applicable for endpoints of type Gateway."
  type        = list(string)
  default     = null
}

variable "subnet_ids" {
  description = "The ID of one or more subnets in which to create a network interface for the endpoint."
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "create_security_group" {
  description = "Create SG for each endpoint_type == Interface"
  type        = bool
  default     = false
}

variable "endpoint_policies" {
  description = "VPC endpoint policies."
  type        = any
  default     = {}
}

variable "endpoints" {
  description = "A list of endpoints objects."
  /*
  object({
    service_name        = string
    vpc_endpoint_type   = string
    private_dns_enabled = bool
    ip_address_type     = string
    dns_options         = map(string)
    security_group_ids   = list(string)
    route_table_ids     = list(string)
    subnet_ids          = list(string)
    auto_accept         = bool
  })
  */
  type    = any
  default = {}
  validation {
    condition = alltrue([
      for k, v in var.endpoints : !can(v.ip_address_type) || (can(v.ip_address_type) && contains(["ipv4", "dualstack", "ipv6"], lookup(v, "ip_address_type", "")))
    ])
    error_message = "`ip_address_type` must be oneof `ipv4`, `dualstack`, `ipv6`"
  }
  validation {
    condition = alltrue([
      for k, v in var.endpoints : !can(v.vpc_endpoint_type) || (can(v.vpc_endpoint_type) && contains(["Gateway", "GatewayLoadBalancer", "Interface"], lookup(v, "vpc_endpoint_type", "")))
    ])
    error_message = "`vpc_endpoint_type` must be oneof `Gateway`, `GatewayLoadBalancer` or `Interface`."
  }
  validation {
    condition = alltrue([
      for k, v in var.endpoints : !can(v.service_name) || (can(v.service_name) && length(lookup(v, "service_name", "")) > 0)
    ])
    error_message = "If `service_name` has beed defined it can not be an ampty string."
  }
  validation {
    condition = alltrue([
      for k, v in var.endpoints : !can(v.dns_options.dns_record_ip_type) || (can(v.dns_options.dns_record_ip_type) && contains(["ipv4", "dualstack", "service-defined", "ipv6"], lookup(lookup(v, "dns_options", {}), "dns_record_ip_type", "")))
    ])
    error_message = "If `dns_options` is defined it must contain field `dns_record_ip_type` only with oneof `ipv4`, `dualstack`, `service`, `ipv6` value."
  }
  validation {
    condition = alltrue([
      for k, v in var.endpoints : !can(v.security_group_ids) || (can(v.security_group_ids) && length(distinct(compact(lookup(v, "security_group_ids", [])))) > 0 && lookup(v, "vpc_endpoint_type", "") == "Interface")
    ])
    error_message = "`security_group_ids` must not be an ampty array and applicable only with `vpc_endpoint_type = Interface`."
  }
  validation {
    condition = alltrue([
      for k, v in var.endpoints : !can(v.private_dns_enabled) || (can(v.private_dns_enabled) && lookup(v, "vpc_endpoint_type", "Gateway") == "Interface" && contains([true, false], lookup(v, "private_dns_enabled", "")))
    ])
    error_message = "`private_dns_enabled` applicable only with `vpc_endpoint_type == Interface`."
  }
  validation {
    condition = alltrue([
      for k, v in var.endpoints : !can(v.route_table_ids) || (can(v.route_table_ids) && length(lookup(v, "route_table_ids", [])) > 0 && lookup(v, "vpc_endpoint_type", "Gateway") == "Gateway")
    ])
    error_message = "`route_table_ids` must not be empty and applicable only with `vpc_endpoint_type = Gateway`."
  }
  validation {
    condition = alltrue([
      for k, v in var.endpoints : !can(v.subnet_ids) || (can(v.subnet_ids) && length(distinct(compact(lookup(v, "subnet_ids", [])))) > 0 && contains(["GatewayLoadBalancer", "Interface"], lookup(v, "vpc_endpoint_type", "Gateway")))
    ])
    error_message = "`subnet_ids` applicable for endpoints of type GatewayLoadBalancer and Interface"
  }
  validation {
    condition = alltrue([
      for k, v in var.endpoints : !can(v.auto_accept) || (can(v.auto_accept) && contains([true, false], lookup(v, "auto_accept", "")))
    ])
    error_message = "`auto_accept` must be only bool value."
  }
}

