terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.26"
    }
  }
}

provider "azurerm" {
   features {
    resource_group {
       prevent_deletion_if_contains_resources = false
     }
   }
}

# Create a resource group
resource "azurerm_resource_group" "Production" {
  name     = var.resource_group_name
  location = "Central India"
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = azurerm_resource_group.Production.name
  location            = azurerm_resource_group.Production.location
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "Subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.Production.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}

  resource "azurerm_network_interface" "Nic" {
  name                = var.network_interface_name
  location            = azurerm_resource_group.Production.location
  resource_group_name = azurerm_resource_group.Production.name

    ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.Subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.PUB_IP.id
  }
}

resource "azurerm_public_ip" "PUB_IP" {
  name                = var.public_ip_name
  resource_group_name = azurerm_resource_group.Production.name
  location            = azurerm_resource_group.Production.location
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_machine" "ProdSrv" {
  name                  = var.virtual_machine_name
  location              = azurerm_resource_group.Production.location
  resource_group_name   = azurerm_resource_group.Production.name
  network_interface_ids = [azurerm_network_interface.Nic.id]
  vm_size               = "Standard_B1s"

storage_image_reference {
   publisher = "Canonical"
   offer     = "UbuntuServer"
   sku       = "18.04-LTS"
   version   = "latest"
  }
    storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
    os_profile {
    computer_name  = "WebSrv"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}

output "public_ip" {
  value = azurerm_public_ip.PUB_IP.ip_address
}
