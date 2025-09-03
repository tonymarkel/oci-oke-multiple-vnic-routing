resource "oci_identity_compartment" "tony_sandbox_compartment"{
    compartment_id = var.tenancy_ocid
    description = "Test Tony OKE Sandbox"
    name = "tony_OKE_sandbox_compartment"
}