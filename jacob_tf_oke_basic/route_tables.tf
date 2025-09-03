resource "oci_core_route_table" "routetable-KubernetesAPIendpoint" {
  compartment_id = oci_identity_compartment.tony_sandbox_compartment.id
  vcn_id         = oci_core_vcn.tony_sandbox_vcn.id
  display_name   = "Kubernetes API Endpoint Route Table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet-gateway-0.id
  }
}

resource "oci_core_route_table" "routetable-workernodes" {
  compartment_id = oci_identity_compartment.tony_sandbox_compartment.id
  vcn_id         = oci_core_vcn.tony_sandbox_vcn.id
  display_name   = "Worker Nodes Route Table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat-gateway-0.id
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.service-gateway-0.id
  }
}

resource "oci_core_route_table" "routetable-serviceloadbalancers" {
  compartment_id = oci_identity_compartment.tony_sandbox_compartment.id
  vcn_id         = oci_core_vcn.tony_sandbox_vcn.id
  display_name   = "Service Load Balancers Route Table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet-gateway-0.id
  }
}