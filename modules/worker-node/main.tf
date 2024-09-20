resource "null_resource" "join_cluster" {
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      host     = var.host
    }

    inline = [
      "sudo kubeadm join ${var.control_plane_endpoint} --token ${var.token} --discovery-token-ca-cert-hash ${var.ca_cert_hash}",
    ]
  }
}
