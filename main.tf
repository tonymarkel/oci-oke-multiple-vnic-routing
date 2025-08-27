# Data sources
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_containerengine_cluster_option" "oke_cluster_option" {
  cluster_option_id = "all"
}

data "oci_containerengine_node_pool_option" "oke_node_pool_option" {
  node_pool_option_id = "all"
}

# Get the latest Oracle Linux image
data "oci_core_images" "node_pool_images" {
  compartment_id           = var.oke_compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = "VM.Standard.E5.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# VCN in network compartment
resource "oci_core_vcn" "oke_vcn" {
  compartment_id = var.network_compartment_ocid
  cidr_blocks    = ["192.168.0.0/16"]
  display_name   = "oke-vcn"
  dns_label      = "okevcn"
}

# Internet Gateway
resource "oci_core_internet_gateway" "oke_internet_gateway" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "oke-internet-gateway"
}

# NAT Gateway
resource "oci_core_nat_gateway" "oke_nat_gateway" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "oke-nat-gateway"
}

# Service Gateway
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "oke_service_gateway" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "oke-service-gateway"
  
  services {
    service_id = data.oci_core_services.all_services.services[0]["id"]
  }
}

# Route Tables
resource "oci_core_default_route_table" "oke_default_route_table" {
  manage_default_resource_id = oci_core_vcn.oke_vcn.default_route_table_id
  display_name               = "oke-default-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.oke_internet_gateway.id
  }
}

resource "oci_core_route_table" "oke_private_route_table" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "oke-private-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.oke_nat_gateway.id
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0]["cidr_block"]
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.oke_service_gateway.id
  }
}

# Security Lists
resource "oci_core_default_security_list" "oke_default_security_list" {
  manage_default_resource_id = oci_core_vcn.oke_vcn.default_security_list_id
  display_name               = "oke-default-security-list"

  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  ingress_security_rules {
    stateless   = false
    source      = "192.168.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "all"
  }
}

resource "oci_core_security_list" "oke_api_endpoint_security_list" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "oke-api-endpoint-security-list"

  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "192.168.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    
    tcp_options {
      max = "12250"
      min = "12250"
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "192.168.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "1"
    
    icmp_options {
      type = "3"
      code = "4"
    }
  }
}

resource "oci_core_security_list" "oke_node_security_list" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "oke-node-security-list"

  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  ingress_security_rules {
    stateless   = false
    source      = "192.168.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "all"
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    
    tcp_options {
      max = "22"
      min = "22"
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    
    tcp_options {
      max = "30000"
      min = "30000"
    }
  }
}

# Subnets
resource "oci_core_subnet" "oke_api_endpoint_subnet" {
  compartment_id      = var.network_compartment_ocid
  vcn_id              = oci_core_vcn.oke_vcn.id
  cidr_block          = "192.168.1.0/24"
  display_name        = "oke-api-endpoint-subnet"
  dns_label           = "k8sapi"
  security_list_ids   = [oci_core_security_list.oke_api_endpoint_security_list.id]
  route_table_id      = oci_core_vcn.oke_vcn.default_route_table_id
  dhcp_options_id     = oci_core_vcn.oke_vcn.default_dhcp_options_id
}

resource "oci_core_subnet" "oke_node_subnet" {
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.oke_vcn.id
  cidr_block                 = "192.168.2.0/24"
  display_name               = "oke-node-subnet"
  dns_label                  = "node"
  security_list_ids          = [oci_core_security_list.oke_node_security_list.id]
  route_table_id             = oci_core_route_table.oke_private_route_table.id
  dhcp_options_id            = oci_core_vcn.oke_vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "oke_load_balancer_subnet" {
  compartment_id    = var.network_compartment_ocid
  vcn_id            = oci_core_vcn.oke_vcn.id
  cidr_block        = "192.168.3.0/24"
  display_name      = "oke-load-balancer-subnet"
  dns_label         = "app"
  security_list_ids = [oci_core_vcn.oke_vcn.default_security_list_id]
  route_table_id    = oci_core_vcn.oke_vcn.default_route_table_id
  dhcp_options_id   = oci_core_vcn.oke_vcn.default_dhcp_options_id
}

# Subnet for secondary VNICs
resource "oci_core_subnet" "oke_secondary_vnic_subnet" {
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.oke_vcn.id
  cidr_block                 = "192.168.4.0/24"
  display_name               = "oke-secondary-vnic-subnet"
  dns_label                  = "nat"
  security_list_ids          = [oci_core_security_list.oke_node_security_list.id]
  route_table_id             = oci_core_route_table.oke_private_route_table.id
  dhcp_options_id            = oci_core_vcn.oke_vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = false
}

# Subnet for Pods
resource "oci_core_subnet" "oke_pod_subnet" {
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.oke_vcn.id
  cidr_block                 = "192.168.5.0/22"
  display_name               = "oke-pod-subnet"
  dns_label                  = "services"
  security_list_ids          = [oci_core_security_list.oke_node_security_list.id]
  route_table_id             = oci_core_route_table.oke_private_route_table.id
  dhcp_options_id            = oci_core_vcn.oke_vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
}

# OKE Cluster
resource "oci_containerengine_cluster" "oke_cluster" {
  compartment_id     = var.oke_compartment_ocid
  kubernetes_version = data.oci_containerengine_cluster_option.oke_cluster_option.kubernetes_versions[0]
  name               = "oke-cluster"
  vcn_id             = oci_core_vcn.oke_vcn.id

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.oke_api_endpoint_subnet.id
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.oke_load_balancer_subnet.id]
    
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled              = false
    }

    admission_controller_options {
      is_pod_security_policy_enabled = false
    }

    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }
}

# Node Pool
resource "oci_containerengine_node_pool" "oke_node_pool" {
  cluster_id         = oci_containerengine_cluster.oke_cluster.id
  compartment_id     = var.oke_compartment_ocid
  kubernetes_version = data.oci_containerengine_cluster_option.oke_cluster_option.kubernetes_versions[0]
  name               = "oke-node-pool"
  node_shape         = "VM.Standard.E5.Flex"

  node_shape_config {
    ocpus         = 1
    memory_in_gbs = 8
  }

  node_source_details {
    image_id    = data.oci_core_images.node_pool_images.images[0].id
    source_type = "IMAGE"
  }

  node_config_details {
    placement_configs {
      availability_domain = var.availability_domain
      subnet_id           = oci_core_subnet.oke_node_subnet.id
    }
    node_pool_pod_network_option_details {
      cni_type = "OCI_VCN_IP_NATIVE"
      pod_subnet_ids = [oci_core_subnet.oke_pod_subnet.id]
    }
    size = 3
  }

  initial_node_labels {
    key   = "name"
    value = "oke-cluster"
  }
  
  ssh_public_key = file("~/.ssh/id_rsa.pub") # Update this path to your public key
}

resource "oci_core_vnic_attachment" "oke_secondary_vnic_attachment" {
  count       = 3
  instance_id = oci_containerengine_node_pool.oke_node_pool.nodes[count.index].id
  # nic_index   = count.index
  create_vnic_details {
    assign_public_ip       = true
    subnet_id              = oci_core_subnet.oke_secondary_vnic_subnet.id
    display_name           = "oke-secondary-vnic-${count.index + 1}"
    hostname_label         = "okesecondary${count.index + 1}"
    skip_source_dest_check = true
  }
}

# Output values
output "cluster_id" {
  description = "ID of the OKE cluster"
  value       = oci_containerengine_cluster.oke_cluster.id
}

output "vcn_id" {
  description = "ID of the VCN"
  value       = oci_core_vcn.oke_vcn.id
}

output "node_pool_id" {
  description = "ID of the node pool"
  value       = oci_containerengine_node_pool.oke_node_pool.id
}

output "node_instance_ocid" {
  description = "ID of the nodes used for NAT"
  value       = oci_containerengine_node_pool.oke_node_pool.nodes[*].id
}

output "cluster_endpoints" {
  description = "Kubernetes cluster endpoints"
  value = {
    public_endpoint  = oci_containerengine_cluster.oke_cluster.endpoints[0].public_endpoint
    private_endpoint = oci_containerengine_cluster.oke_cluster.endpoints[0].private_endpoint
  }
}

output "secondary_vnic_subnet_id" {
  description = "ID of the secondary VNIC subnet"
  value       = oci_core_subnet.oke_secondary_vnic_subnet.id
}