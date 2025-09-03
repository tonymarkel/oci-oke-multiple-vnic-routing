resource "oci_core_vcn" "tony_sandbox_vcn"{
    cidr_block = "10.0.0.0/16"
    display_name = "TonySandboxVCN"
    compartment_id = oci_identity_compartment.tony_sandbox_compartment.id
    dns_label = "tonysb"
}

resource "oci_core_subnet" "oke_api_endpoint_subnet" {
  compartment_id                 = oci_identity_compartment.tony_sandbox_compartment.id
  vcn_id                         = oci_core_vcn.tony_sandbox_vcn.id
  display_name                   = "KubernetesAPIendpoint"
  cidr_block                     = "10.0.20.0/30"
  prohibit_public_ip_on_vnic     = false
  route_table_id                 = oci_core_route_table.routetable-KubernetesAPIendpoint.id
  security_list_ids              = [oci_core_security_list.seclist-KubernetesAPIendpoint.id]
  dhcp_options_id                = oci_core_vcn.tony_sandbox_vcn.default_dhcp_options_id
}

resource "oci_core_subnet" "workernodes" {
  compartment_id                 = oci_identity_compartment.tony_sandbox_compartment.id
  vcn_id                         = oci_core_vcn.tony_sandbox_vcn.id
  display_name                   = "workernodes"
  cidr_block                     = "10.0.1.0/24"
  prohibit_public_ip_on_vnic     = true                                     # Private subnet
  route_table_id                 = oci_core_route_table.routetable-workernodes.id
  security_list_ids              = [oci_core_security_list.seclist-workernodes.id]
  dhcp_options_id                = oci_core_vcn.tony_sandbox_vcn.default_dhcp_options_id
  # Optional: Set dns_label if you want custom DNS, otherwise DNS resolution is enabled by default
}

resource "oci_core_subnet" "loadbalancers" {
  compartment_id                 = oci_identity_compartment.tony_sandbox_compartment.id
  vcn_id                         = oci_core_vcn.tony_sandbox_vcn.id
  display_name                   = "loadbalancers"
  cidr_block                     = "10.0.2.0/24"
  prohibit_public_ip_on_vnic     = false                                    # Public subnet
  route_table_id                 = oci_core_route_table.routetable-serviceloadbalancers.id
  security_list_ids              = [oci_core_security_list.seclist_loadbalancers.id]
  dhcp_options_id                = oci_core_vcn.tony_sandbox_vcn.default_dhcp_options_id
}

resource "oci_core_subnet" "bastion" {
  compartment_id                 = oci_identity_compartment.tony_sandbox_compartment.id
  vcn_id                         = oci_core_vcn.tony_sandbox_vcn.id
  display_name                   = "bastion"
  cidr_block                     = "10.0.3.0/24"
  prohibit_public_ip_on_vnic     = true                                     # Private subnet
  # For bastion, you may or may not associate a custom route table; using default here unless specified otherwise
  # If you have a specific route table for bastion, add: route_table_id = oci_core_route_table.<your-bastion-route-table>.id
  security_list_ids              = [oci_core_security_list.seclist_bastion.id]
  dhcp_options_id                = oci_core_vcn.tony_sandbox_vcn.default_dhcp_options_id
}