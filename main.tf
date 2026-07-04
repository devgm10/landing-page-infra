module "network" {
    source          = "./modules/network"
    project_name    = var.project_name
}

module "compute" {
    source              = "./modules/compute"
    project_name        = var.project_name
    instance_type       = var.instance_type
    ssh_public_key      = var.ssh_public_key
    security_group_id   = module.network.security_group_id
}