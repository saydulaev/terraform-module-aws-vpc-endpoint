locals {
  endpoints = { for key, endpoint in var.endpoints : replace(replace(key, "_", "."), "-", ".") => merge({
    service_name        = length(lookup(endpoint, "service_name", "")) > 0 ? lookup(endpoint, "service_name") : "com.amazonaws.${data.aws_region.current.name}.${replace(replace(key, "_", "."), "-", ".")}" //  SageMaker Notebook service only condition rule.
    vpc_endpoint_type   = lookup(endpoint, "vpc_endpoint_type", "Gateway")
    security_group_ids  = alltrue([lookup(endpoint, "vpc_endpoint_type", "Gateway") == "Interface", lookup(endpoint, "security_group_ids", false)]) ? coalescelist(endpoint.security_group_ids, var.security_group_ids) : null
    private_dns_enabled = lookup(endpoint, "vpc_endpoint_type", "Gateway") == "Interface" ? lookup(endpoint, "private_dns_enabled", false) : null
    policy              = contains(["Gateway", "Interface"], lookup(endpoint, "vpc_endpoint_type", null)) ? lookup(local.endpoint_policies, key, null) : null
    route_table_ids     = lookup(endpoint, "vpc_endpoint_type", null) == "Gateway" ? coalescelist(lookup(endpoint, "route_table_ids", []), var.route_table_ids) : null
    subnet_ids          = contains(["GatewayLoadBalancer", "Interface"], lookup(endpoint, "vpc_endpoint_type", null)) ? coalesce(lookup(endpoint, "subnet_ids", []), var.subnet_ids) : null
    ip_address_type     = lookup(endpoint, "ip_address_type", null)
    auto_accept         = lookup(endpoint, "auto_accept", null)
    dns_options         = lookup(endpoint, "dns_options", null)
    tags                = merge(
      var.tags,
      {
        Name = format("%s-%s", lower(var.vpc_name), lower(replace(replace(key, "_", "."), "-", ".")))
        "Pluto:CostCenter"  = "Networking",
        "Pluto:Application" = "VPCEndpoint"
      })
  }) }

  endpoint_policies = var.endpoint_policies
}

data "aws_region" "current" {}

data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_vpc_endpoint_service" "this" {
  for_each = local.endpoints

  service      = each.key
  service_type = lookup(each.value, "vpc_endpoint_type", "Interface")
}

resource "aws_vpc_endpoint" "this" {
  for_each = local.endpoints

  vpc_id              = var.vpc_id
  service_name        = data.aws_vpc_endpoint_service.this[each.key].service_name
  vpc_endpoint_type   = each.value.vpc_endpoint_type
  security_group_ids  = var.create_security_group && each.value.vpc_endpoint_type == "Interface" ? [aws_security_group.this[each.key].id] : each.value.security_group_ids
  private_dns_enabled = each.value.private_dns_enabled
  policy              = each.value.policy
  route_table_ids     = each.value.route_table_ids
  subnet_ids          = each.value.subnet_ids
  ip_address_type     = each.value.ip_address_type
  auto_accept         = each.value.auto_accept

  tags = each.value.tags

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "aws_security_group" "this" {
  for_each    = var.create_security_group ? { for k, v in local.endpoints : k => v if v.vpc_endpoint_type == "Interface" } : {}
  name        = "${lookup(each.value.tags, "Name", each.key)}-endpoint"
  description = "Allow all traffic from VPC ${data.aws_vpc.this.arn}"
  vpc_id      = var.vpc_id

  tags = merge(each.value.tags)
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  description       = "Allow ingress HTTPS traffic"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = anytrue([lookup(each.value, "ip_address_type", "") == "ipv4", lookup(each.value, "ip_address_type", "") == "dualstack"]) ? ["0.0.0.0/0"] : null
  ipv6_cidr_blocks  = anytrue([lookup(each.value, "ip_address_type", "") == "ipv6", lookup(each.value, "ip_address_type", "") == "dualstack"]) ? ["::/0"] : null
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  description       = "Allow egress HTTPS traffic"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = anytrue([lookup(each.value, "ip_address_type", "") == "ipv4", lookup(each.value, "ip_address_type", "") == "dualstack"]) ? ["0.0.0.0/0"] : null
  ipv6_cidr_blocks  = anytrue([lookup(each.value, "ip_address_type", "") == "ipv6", lookup(each.value, "ip_address_type", "") == "dualstack"]) ? ["::/0"] : null
  security_group_id = aws_security_group.this.id
}