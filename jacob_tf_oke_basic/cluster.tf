
resource "oci_containerengine_cluster" "tony_oke_cluster" {
  compartment_id     = oci_identity_compartment.tony_sandbox_compartment.id
  name               = "tony-oke-cluster"
  vcn_id             = oci_core_vcn.tony_sandbox_vcn.id
  kubernetes_version  = "v1.33.1"
  
  endpoint_config {
    is_public_ip_enabled = false
    subnet_id            = oci_core_subnet.oke_api_endpoint_subnet.id
    # Optionally, add nsg_ids for further security using Network Security Groups
  }

  options {
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }
}

resource "oci_containerengine_node_pool" "oke_nodepool" {
  compartment_id      = oci_identity_compartment.tony_sandbox_compartment.id
  cluster_id          = oci_containerengine_cluster.tony_oke_cluster.id
  name                = "oke-nodepool"
  node_shape          = "VM.Standard.E3.Flex"
  kubernetes_version  = "v1.33.1"

  node_config_details {
    size = 2
    placement_configs {
      availability_domain = var.availability_domain
      subnet_id           = oci_core_subnet.workernodes.id
    }
  }
  
  node_shape_config {
    ocpus = 1
    memory_in_gbs = 8
  }  

  node_source_details {
    source_type = "IMAGE"
    image_id    = var.node_image_id  
  }
}