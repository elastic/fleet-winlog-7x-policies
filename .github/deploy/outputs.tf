output "elasticsearch_url" {
  value = ec_deployment.fleet-winlog.elasticsearch[0].https_endpoint
}

output "kibana_url" {
  value = local.kibana_url
}

output "elasticsearch_username" {
  value = ec_deployment.fleet-winlog.elasticsearch_username
}

output "elasticsearch_password" {
  sensitive = true
  value     = ec_deployment.fleet-winlog.elasticsearch_password
}

output "fleet_server_url" {
  value = local.fleet_server_url
}

output "agent_policy_id" {
  value = local.agent_policy_id
}

output "enrollment_token" {
  sensitive = true
  value     = local.enrollment_api_key.api_key
}

output "stack_version" {
  value = var.stack_version
}

output "count_reader_api_key" {
  sensitive = true
  value     = elasticstack_elasticsearch_security_api_key.count-reader.encoded
}