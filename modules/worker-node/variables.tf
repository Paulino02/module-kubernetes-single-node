variable "ssh_user" {
  type        = string
  description = "Usuário SSH"
}

variable "ssh_password" {
  type        = string
  description = "Senha SSH"
}

variable "host" {
  type        = string
  description = "Endereço IP do nó worker"
}

variable "control_plane_endpoint" {
  type        = string
  description = "Endpoint do Control Plane"
}

variable "token" {
  type        = string
  description = "Token de autenticação para o join"
}

variable "ca_cert_hash" {
  type        = string
  description = "Hash do certificado CA para o join"
}
