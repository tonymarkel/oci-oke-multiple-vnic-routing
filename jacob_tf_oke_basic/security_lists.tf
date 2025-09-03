
resource "oci_core_security_list" "seclist-KubernetesAPIendpoint" {

  compartment_id = oci_identity_compartment.tony_sandbox_compartment.id
  vcn_id         = oci_core_vcn.tony_sandbox_vcn.id
  display_name   = "Kubernetes API Endpoint Security List"

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    # Kubernetes worker to Kubernetes API endpoint communication 
    protocol = "6" 
    source   = "10.0.1.0/24"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    # Kubernetes worker to control pane authentication
    protocol = "6" 
    source   = "10.0.1.0/24"
    tcp_options {
      min = 12250
      max = 12250
    }
  }

  ingress_security_rules {
    # Path Discovery
    protocol = "1" #ICMP 
    source   = "10.0.1.0/24"
    icmp_options {
        type = 3
        code = 4
    }
  }
  # 1. All region services in Oracle Services Network - TCP/ALL (Allow Kubernetes control plane to communicate with OKE)
  egress_security_rules {
    protocol    = "6" # TCP
    destination = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    # all ports, so no tcp_options needed
  }

  # 2. All region services in Oracle Services Network - ICMP 3,4 (Path Discovery)
  egress_security_rules {
    protocol    = "1" # ICMP
    destination = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    icmp_options {
      type = 3
      code = 4
    }
  }

  # 3. 10.0.1.0/24 (Worker Nodes CIDR) - TCP/ALL (Allow control plane to talk to workers)
  egress_security_rules {
    protocol    = "6" # TCP
    destination = "10.0.1.0/24"
    destination_type = "CIDR_BLOCK"
    # all ports, so no tcp_options needed
  }

  # 4. 10.0.1.0/24 (Worker Nodes CIDR) - ICMP 3,4 (Path Discovery)
  egress_security_rules {
    protocol    = "1" # ICMP
    destination = "10.0.1.0/24"
    destination_type = "CIDR_BLOCK"
    icmp_options {
      type = 3
      code = 4
    }
  }
}


resource "oci_core_security_list" "seclist-workernodes" {

  compartment_id = oci_identity_compartment.tony_sandbox_compartment.id
  vcn_id         = oci_core_vcn.tony_sandbox_vcn.id
  display_name   = "Worker Nodes Security List"

  ingress_security_rules {
    protocol = "all"
    source   = "10.0.1.0/24"
  }

  # 2. Kubernetes API Endpoint CIDR - TCP/ALL ports
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "10.0.0.0/30"
    # No tcp_options: all ports
  }

  # 3. 0.0.0.0/0 - ICMP type 3 code 4 (Path Discovery)
  ingress_security_rules {
    protocol = "1" # ICMP
    source   = "0.0.0.0/0"
    icmp_options {
      type = 3
      code = 4
    }
  }

  # 4. Bastion Subnet CIDR (or specific CIDR) - TCP/22 (SSH)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "10.0.3.0/24" 
    tcp_options {
      min = 22
      max = 22
    }
  }

  # 5. Load balancer subnet CIDR - ALL protocols/ports 30000-32767 (node ports)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "10.0.2.0/24" 
    tcp_options {
        min = 30000
        max = 32767
    }
  }

     # UDP
  ingress_security_rules {
    protocol = "17" # UDP
    source   = "10.0.2.0/24" 
    udp_options {
        min = 30000
        max = 32767
    }
  }

  # 6. Load balancer subnet CIDR - ALL protocols/port 10256 (kube-proxy)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "10.0.2.0/24" 
    tcp_options {
        min = 10256
        max = 10256
    }
  }

     # UDP
  ingress_security_rules {
    protocol = "17" # UDP
    source   = "10.0.2.0/24" 
    udp_options {
        min = 10256
        max = 10256
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "10.0.1.0/24"
    destination_type = "CIDR_BLOCK"
  }

  # 2. 0.0.0.0/0 - ICMP type 3 code 4 (Path Discovery)
  egress_security_rules {
    protocol    = "1" # ICMP
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    icmp_options {
      type = 3
      code = 4
    }
  }

  # 3. All region services in Oracle Services Network - TCP/ALL
  egress_security_rules {
    protocol    = "6" # TCP
    destination = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    # all TCP ports, so no tcp_options needed
  }

  # 4. Kubernetes API Endpoint CIDR - TCP/6443
  egress_security_rules {
    protocol    = "6" # TCP
    destination = "10.0.0.0/30"
    destination_type = "CIDR_BLOCK"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # 5. Kubernetes API Endpoint CIDR - TCP/12250
  egress_security_rules {
    protocol    = "6" # TCP
    destination = "10.0.0.0/30"
    destination_type = "CIDR_BLOCK"
    tcp_options {
      min = 12250
      max = 12250
    }
  }

  # 6. 0.0.0.0/0 - TCP/ALL (optional, Internet access)
  egress_security_rules {
    protocol    = "6" # TCP
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    # all TCP ports, so no tcp_options needed
  }
}

resource "oci_core_security_list" "seclist_loadbalancers" {
  compartment_id = oci_identity_compartment.tony_sandbox_compartment.id
  vcn_id         = oci_core_vcn.tony_sandbox_vcn.id

  ##################
  # Ingress Rules  #
  ##################

  # Example: Allow HTTPS from the Internet (TCP/443)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Example: Allow HTTP from the Internet (TCP/80) - optional
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # Example: Allow custom app port (TCP/8080) from a specific CIDR - optional
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "203.0.113.0/24" # Replace with your CIDR as needed.
    tcp_options {
      min = 8080
      max = 8080
    }
  }

  # Add, remove, or modify ingress rules as needed for your listeners/services

  ##################
  # Egress Rules   #
  ##################

  # Node ports 30000-32767 to worker nodes (TCP)
  egress_security_rules {
    protocol    = "6" # TCP
    destination = "10.0.1.0/24"
    destination_type = "CIDR_BLOCK"
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  # Node ports 30000-32767 to worker nodes (UDP)
  egress_security_rules {
    protocol    = "17" # UDP
    destination = "10.0.1.0/24"
    destination_type = "CIDR_BLOCK"
    udp_options {
      min = 30000
      max = 32767
    }
  }

  # Kube-proxy port 10256 to worker nodes (TCP)
  egress_security_rules {
    protocol    = "6" # TCP
    destination = "10.0.1.0/24"
    destination_type = "CIDR_BLOCK"
    tcp_options {
      min = 10256
      max = 10256
    }
  }

  # Kube-proxy port 10256 to worker nodes (UDP)
  egress_security_rules {
    protocol    = "17" # UDP
    destination = "10.0.1.0/24"
    destination_type = "CIDR_BLOCK"
    udp_options {
      min = 10256
      max = 10256
    }
  }
}

resource "oci_core_security_list" "seclist_bastion" {
  compartment_id = oci_identity_compartment.tony_sandbox_compartment.id
  vcn_id         = oci_core_vcn.tony_sandbox_vcn.id

  ##################
  # Ingress Rules  #
  ##################
  # None: This means no ingress_security_rules block is included.

  ##################
  # Egress Rules   #
  ##################

  # 1. Optional: Allow bastion to access Kubernetes API endpoint (TCP/6443)
  egress_security_rules {
    protocol    = "6" # TCP
    destination = "10.0.0.0/30"
    destination_type = "CIDR_BLOCK"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # 2. Optional: Allow SSH traffic to worker nodes (TCP/22)
  egress_security_rules {
    protocol    = "6" # TCP
    destination = "10.0.1.0/24"
    destination_type = "CIDR_BLOCK"
    tcp_options {
      min = 22
      max = 22
    }
  }
}