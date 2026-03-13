resource "azurerm_resource_group" "groupe" {
  name     = var.nom_groupe
  location = var.localisation
}

resource "azurerm_virtual_network" "reseau" {
  name                = "vnet-flask"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.groupe.location
  resource_group_name = azurerm_resource_group.groupe.name
}

resource "azurerm_subnet" "sous_reseau" {
  name                 = "subnet-flask"
  resource_group_name  = azurerm_resource_group.groupe.name
  virtual_network_name = azurerm_virtual_network.reseau.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "ip_publique" {
  name                = "ip-flask"
  location            = azurerm_resource_group.groupe.location
  resource_group_name = azurerm_resource_group.groupe.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "carte_reseau" {
  name                = "nic-flask"
  location            = azurerm_resource_group.groupe.location
  resource_group_name = azurerm_resource_group.groupe.name

  ip_configuration {
    name                          = "config-ip"
    subnet_id                     = azurerm_subnet.sous_reseau.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip_publique.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-flask"
  resource_group_name = azurerm_resource_group.groupe.name
  location            = azurerm_resource_group.groupe.location
  size                = var.vm_size
  admin_username      = var.nom_utilisateur

  network_interface_ids = [
    azurerm_network_interface.carte_reseau.id,
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.nom_utilisateur
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "random_string" "storage_suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_storage_account" "stockage" {
  name                     = "${var.storage_account_prefix}${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.groupe.name
  location                 = azurerm_resource_group.groupe.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "conteneur" {
  name                  = "fichiers"
  storage_account_name  = azurerm_storage_account.stockage.name
  container_access_type = "private"
}