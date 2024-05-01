module "vpc-endpoint" {
  source             = "../vpc-endpoint"
  endpoint_policies  = local.endpoint_policies
  vpc_id             = "vpc_123456789"
  //create_security_group = true
  security_group_ids = ["sg_123456789", "sg_987654321"]
  subnet_ids         = ["subnet_123456789", "subnet_987654321", "subnet_123459876"]
  route_table_ids    = ["rt_123456789"]
  endpoints = {
    s3 = {
      vpc_endpoint_type       = "Gateway"
    },
    sts = {
      vpc_endpoint_type       = "Interface"
      private_dns_enabled     = false
      security_group_ids      = ["sg_sts_123456789"]
    },
    "ecr.api" = {
      vpc_endpoint_type       = "Interface"
      private_dns_enabled     = true
      security_group_ids      = ["sg_ecrapi_123456789"]
    },
    "ecr.dkr" = {
      vpc_endpoint_type       = "Interface"
      private_dns_enabled     = true
      security_group_id       = ["sg_ecrdkr_123456789"]
    },
    elasticloadbalancing = {
      vpc_endpoint_type       = "Interface"
      private_dns_enabled     = false
      security_group_id       = ["sg_elasticloadbalancing_123456789"]
    },
    logs = {
      vpc_endpoint_type       = "Interface"
      private_dns_enabled     = false
      security_group_id       = ["sg_logs_123456789"]
    },
    self_service = {
      vpc_endpoint_type       = "Interface"
      private_dns_enabled     = true
      ip_address_type         = "ipv4"
      service_name            = "com.selfcompany.some-service-endpoint"
      security_group_id       = ["sg_self_123456789", "sg_self_987654321"]
      subnet_ids              = ["subnet_self_123456789", "subnet_sefl_987654321"]
      dns_options = {
        dns_record_ip_type = "ipv4"
      }
    },
  }
}