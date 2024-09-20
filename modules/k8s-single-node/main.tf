resource "null_resource" "init_control_plane" {
  provisioner "file" {
    source      = "modules/control-plane/scriptk8s.sh"  # Caminho do script na máquina local
    destination = "/tmp/scriptk8s.sh"  # Caminho na máquina remota
    connection {
      type     = "ssh"
      host     = var.host
      user     = var.ssh_user
      password = var.ssh_password
    }
  }
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      host     = var.host
    }

    inline = [
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh"
      # Instala rede de pods (Calico como exemplo)
      #"kubectl apply -f https://docs.projectcalico.org/v3.25/manifests/calico.yaml", 
    ]
  }
}