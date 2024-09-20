#module "kubeadm_install" {
#  source = "./modules/kubeadm-install"
#  ssh_user     = var.ssh_user
#  ssh_password = var.ssh_password
#  host         = var.master_ip
#}

module "control_plane" {
  source = "./modules/k8s-single-node"
  ssh_user     = var.ssh_user
  ssh_password = var.ssh_password
  host         = var.master_ip
}

#module "worker_nodes" {
#  source = "./modules/node-configuration"
#  ssh_user              = var.ssh_user
#  ssh_password          = var.ssh_password
#  host                  = var.worker_ip
#  control_plane_endpoint = var.control_plane_ip
#  token                 = var.token
#  ca_cert_hash          = var.ca_cert_hash
   #depends_on = [module.control_plane]
#}