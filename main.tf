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

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-flask"
  location            = azurerm_resource_group.groupe.location
  resource_group_name = azurerm_resource_group.groupe.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Backend"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.backend_port)
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
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

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.carte_reseau.id
  network_security_group_id = azurerm_network_security_group.nsg.id
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

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt update && apt upgrade -y
    apt install -y python3 python3-pip git
    pip3 install flask gunicorn azure-storage-blob
    mkdir -p /app
    # Remplacez par votre repo Git
    # git clone https://github.com/votre-user/votre-repo.git /app
    # cd /app
    # Créer un service systemd pour l'app
    cat > /etc/systemd/system/flask-app.service << 'SERVICE_EOF'
[Unit]
Description=Flask App
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/app
ExecStart=/usr/local/bin/gunicorn --bind 0.0.0.0:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE_EOF
    systemctl daemon-reload
    # systemctl enable flask-app
    # systemctl start flask-app
    echo "Installation terminée. Clonez votre repo dans /app, puis activez le service."
  EOF
  )
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