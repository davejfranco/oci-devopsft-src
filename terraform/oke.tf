#OKE cluster
resource "oci_containerengine_cluster" "k8s_cluster" {
    #Required
    compartment_id = var.compartment_id
    kubernetes_version = reverse(data.oci_containerengine_cluster_option.k8s_latest.kubernetes_versions)[0]
    name = var.cluster_name
    vcn_id = oci_core_vcn.vcn.id

    #Optional
    options {
        #Optional
        add_ons {
            #Optional
            is_kubernetes_dashboard_enabled = var.is_dashboard_enabled
            is_tiller_enabled = var.is_tiller_enabled
        }

        service_lb_subnet_ids = [oci_core_subnet.pub_subnets[0].id]
    }
}

#Get latest Oracle Linux Image available
data "oci_core_images" "nodeImage" {
    #Required
    compartment_id = var.compartment_id

    #Optional
    operating_system = "Oracle Linux"
    operating_system_version = var.linux_version
    shape = var.np_node_shape
    sort_by = "TIMECREATED"
    sort_order = "DESC"
}

resource "oci_containerengine_node_pool" "node_pool" {
    #Required
    cluster_id = oci_containerengine_cluster.k8s_cluster.id
    compartment_id = var.compartment_id
    kubernetes_version = reverse(data.oci_containerengine_cluster_option.k8s_latest.kubernetes_versions)[0]
    name = format("%s_np_1", var.cluster_name)
    node_shape = var.np_node_shape
    node_image_id = data.oci_core_images.nodeImage.images[0].id
    
    node_config_details {

        dynamic "placement_configs" {
            iterator = ad
            for_each = data.oci_identity_availability_domains.ads.availability_domains.*.name
            content {
                availability_domain = ad.value
                subnet_id           = oci_core_subnet.pub_subnets[1].id
            }
    }
    
    size = var.nodes_per_net
  }
    
    #ssh_public_key = file(var.ssh_key_location)
}
