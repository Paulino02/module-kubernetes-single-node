variable "ssh_user" {
  type        = string
  description = "Usuário SSH"
}

variable "ssh_password" {
  type        = string
  description = "Senha SSH"
}

variable "master_ip" {
  type        = string
  description = "IP do Master Node"
}

#variable "worker_ip" {
#  type        = list(string)
#  description = "Lista de IPs dos Worker Nodes"
#}

variable "control_plane_ip" {
  type        = string
  description = "IP do Control Plane"
}

variable "token" {
  type        = string
  description = "Token para adicionar nós ao cluster"
}

variable "ca_cert_hash" {
  type        = string
  description = "Hash do certificado CA"
}
