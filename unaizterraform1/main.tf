# ------------------------------
# Provider
# ------------------------------
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# ------------------------------
# Compartment
# ------------------------------
resource "oci_identity_compartment" "Unaiz_terraform_compartment" {
  compartment_id = var.tenancy_ocid
  description    = "Unaiz's Test Terraform Compartment"
  name           = "Unaiz_Test_Compartment"
}

# ------------------------------
# VCN
# ------------------------------
resource "oci_core_vcn" "unaiz_sandbox_vcn" {
  cidr_block     = "10.0.0.0/16"
  display_name   = "UnaizSandboxVCN"
  compartment_id = oci_identity_compartment.Unaiz_terraform_compartment.id
  dns_label      = "unaizsb"
}

# Internet Gateway
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = oci_identity_compartment.Unaiz_terraform_compartment.id
  display_name   = "internet-gateway-0"
  vcn_id         = oci_core_vcn.unaiz_sandbox_vcn.id
}

# NAT Gateway
resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = oci_identity_compartment.Unaiz_terraform_compartment.id
  display_name   = "nat-gateway-0"
  vcn_id         = oci_core_vcn.unaiz_sandbox_vcn.id
}

# Service Gateway
data "oci_core_services" "all_services" {}
resource "oci_core_service_gateway" "service_gateway" {
  compartment_id = oci_identity_compartment.Unaiz_terraform_compartment.id
  display_name   = "service-gateway-0"
  vcn_id         = oci_core_vcn.unaiz_sandbox_vcn.id

 services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
}



# ------------------------------
# Route Tables
# ------------------------------
resource "oci_core_route_table" "rt_k8s_api" {
  compartment_id = oci_identity_compartment.Unaiz_terraform_compartment.id
  display_name   = "routetable-KubernetesAPIendpoint"
  vcn_id         = oci_core_vcn.unaiz_sandbox_vcn.id

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
    description       = "Route to Internet Gateway"
  }
}

resource "oci_core_route_table" "rt_workernodes" {
  compartment_id = oci_identity_compartment.Unaiz_terraform_compartment.id
  display_name   = "routetable-workernodes"
  vcn_id         = oci_core_vcn.unaiz_sandbox_vcn.id

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
    description       = "Route to NAT Gateway"
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.service_gateway.id
  }
}

resource "oci_core_route_table" "rt_loadbalancers" {
  compartment_id = oci_identity_compartment.Unaiz_terraform_compartment.id
  display_name   = "routetable-serviceloadbalancers"
  vcn_id         = oci_core_vcn.unaiz_sandbox_vcn.id

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
    description       = "Route to Internet Gateway"
  }
}

# ------------------------------
# Security Lists
# ------------------------------
# Kubernetes API Endpoint
resource "oci_core_security_list" "seclist_k8s_api_endpoint" {
  compartment_id = oci_identity_compartment.Unaiz_terraform_compartment.id
  display_name   = "seclist-KubernetesAPIendpoint"
  vcn_id         = oci_core_vcn.unaiz_sandbox_vcn.id

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "10.0.1.0/24"

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "10.0.1.0/24"

    tcp_options {
      min = 12250
      max = 12250
    }
  }

  ingress_security_rules {
    protocol = "1" # ICMP
    source   = "10.0.1.0/24"

    icmp_options {
      type = 3
      code = 4
    }
  }

  egress_security_rules {
  protocol    = "6"
  destination = "0.0.0.0/0"
  tcp_options {
    min = 1
    max = 65535
  }
}
}

# Worker Nodes Security List
resource "oci_core_security_list" "seclist_workernodes" {
  compartment_id = oci_identity_compartment.Unaiz_terraform_compartment.id
  display_name   = "seclist-workernodes"
  vcn_id         = oci_core_vcn.unaiz_sandbox_vcn.id

  ingress_security_rules {
    protocol = "6"
    source   = "10.0.0.0/30"
    tcp_options {
      min = 1
      max = 65535
    }
  }

  egress_security_rules {
    protocol    = "6"
    destination = "10.0.0.0/30"
    tcp_options {
      min = 6443
      max = 6443
    }
  }
}

# Load Balancers Security List
resource "oci_core_security_list" "seclist_loadbalancers" {
  compartment_id = oci_identity_compartment.Unaiz_terraform_compartment.id
  display_name   = "seclist-loadbalancers"
  vcn_id         = oci_core_vcn.unaiz_sandbox_vcn.id
}

# Bastion Security List
resource "oci_core_security_list" "seclist_bastion" {
  compartment_id = oci_identity_compartment.Unaiz_terraform_compartment.id
  display_name   = "seclist-Bastion"
  vcn_id         = oci_core_vcn.unaiz_sandbox_vcn.id
}

# ------------------------------
# Subnets
# ------------------------------
resource "oci_core_subnet" "k8s_api_endpoint_subnet" {
  compartment_id       = oci_identity_compartment.Unaiz_terraform_compartment.id
  vcn_id               = oci_core_vcn.unaiz_sandbox_vcn.id
  display_name         = "KubernetesAPIendpoint"
  cidr_block           = "10.0.0.0/30"
  prohibit_public_ip_on_vnic = false
  route_table_id       = oci_core_route_table.rt_k8s_api.id
  security_list_ids    = [oci_core_security_list.seclist_k8s_api_endpoint.id]
}

resource "oci_core_subnet" "workernodes_subnet" {
  compartment_id    = oci_identity_compartment.Unaiz_terraform_compartment.id
  vcn_id            = oci_core_vcn.unaiz_sandbox_vcn.id
  display_name      = "workernodes"
  cidr_block        = "10.0.1.0/24"
  route_table_id    = oci_core_route_table.rt_workernodes.id
  security_list_ids = [oci_core_security_list.seclist_workernodes.id]
}

resource "oci_core_subnet" "loadbalancers_subnet" {
  compartment_id    = oci_identity_compartment.Unaiz_terraform_compartment.id
  vcn_id            = oci_core_vcn.unaiz_sandbox_vcn.id
  display_name      = "loadbalancers"
  cidr_block        = "10.0.2.0/24"
  route_table_id    = oci_core_route_table.rt_loadbalancers.id
  security_list_ids = [oci_core_security_list.seclist_loadbalancers.id]
}

resource "oci_core_subnet" "bastion_subnet" {
  compartment_id    = oci_identity_compartment.Unaiz_terraform_compartment.id
  vcn_id            = oci_core_vcn.unaiz_sandbox_vcn.id
  display_name      = "bastion"
  cidr_block        = "10.0.3.0/24"
  security_list_ids = [oci_core_security_list.seclist_bastion.id]
}
