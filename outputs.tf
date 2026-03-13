output "ip_publique_vm" {
  description = "Adresse IP publique de la VM"
  value       = azurerm_public_ip.ip_publique.ip_address
}

output "nom_machine_virtuelle" {
  description = "Nom de la machine virtuelle"
  value       = azurerm_linux_virtual_machine.vm.name
}

output "nom_stockage" {
  description = "Nom du compte de stockage"
  value       = azurerm_storage_account.stockage.name
}

output "url_stockage_blob" {
  description = "URL du stockage Blob"
  value       = azurerm_storage_account.stockage.primary_blob_endpoint
}

output "nom_conteneur" {
  description = "Nom du container Blob"
  value       = azurerm_storage_container.conteneur.name
}