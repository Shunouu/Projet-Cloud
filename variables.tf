variable "localisation" {
  description = "Région Azure"
  type        = string
  default     = "France Central"
}

variable "nom_groupe" {
  description = "Nom du Resource Group"
  type        = string
  default     = "rg-projet-flask"
}

variable "nom_utilisateur" {
  description = "Nom d'utilisateur de la VM"
  type        = string
  default     = "utilisateur"
}

variable "ssh_public_key" {
  description = "Clé publique SSH pour la VM (format OpenSSH)"
  type        = string
}

variable "vm_size" {
  description = "Taille de la VM"
  type        = string
  default     = "Standard_B1s"
}

variable "storage_account_prefix" {
  description = "Préfixe du nom du storage account (doit être en minuscules, 3-24 chars au final)"
  type        = string
  default     = "stockageflask"
}