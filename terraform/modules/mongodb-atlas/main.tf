resource "mongodbatlas_project" "project" {
  name   = var.project_name
  org_id = var.org_id
}

resource "mongodbatlas_cluster" "cluster" {   
    project_id              = mongodbatlas_project.project.id
    name                    = var.cluster_name

    # Provider Settings "block"
    provider_name = "TENANT"
    backing_provider_name = var.provider_name
    provider_region_name = var.provider_region_name
    provider_instance_size_name = "M0"
}