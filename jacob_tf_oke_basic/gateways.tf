resource "oci_core_internet_gateway" "internet-gateway-0" {
  compartment_id = oci_identity_compartment.tony_sandbox_compartment.id
  vcn_id         = oci_core_vcn.tony_sandbox_vcn.id
  display_name   = "Internet Gateway 0"
}

resource "oci_core_nat_gateway" "nat-gateway-0" {
  compartment_id = oci_identity_compartment.tony_sandbox_compartment.id
  vcn_id         = oci_core_vcn.tony_sandbox_vcn.id
  display_name = "NAT Gateway 0"
}

resource "oci_core_service_gateway" "service-gateway-0" {
  compartment_id = oci_identity_compartment.tony_sandbox_compartment.id
  vcn_id         = oci_core_vcn.tony_sandbox_vcn.id

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
}

resource "oci_core_dhcp_options" "test_dhcp_options" {
    compartment_id = oci_identity_compartment.tony_sandbox_compartment.id
    vcn_id = oci_core_vcn.tony_sandbox_vcn.id

    options {
      type        = "DomainNameServer"
      server_type = "VcnLocalPlusInternet"
    }
}