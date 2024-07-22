provider "azurerm" {
   features {
   resource_group {
    prevent_deletion_if_contains_resources=false
  }
 }
}

resource "azurerm_resource_group" "myrg1" {
  name     = var.resource_group_name
  location = "Central India"

  tags = {
    Environment = "Terraform Getting Started"
    Team        = "DevOps"
  }
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = "Central India"
  resource_group_name = azurerm_resource_group.myrg1.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.myrg1.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  name                = var.public_ip_name
  location            = "Central India"
  resource_group_name = azurerm_resource_group.myrg1.name
  allocation_method   = "Static"
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "nsg" {
  name                = "mynsg-1"
  location            = "Central India"
  resource_group_name = azurerm_resource_group.myrg1.name

  security_rule {
    name                       = "SSH"
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
    name                       = "AllowAllInbound"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "myvmnic" {
  name                      = "vmnic1"
  location                  = "Central India"
  resource_group_name       = azurerm_resource_group.myrg1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

# Associate Network Security Group with Network Interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.myvmnic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                  = var.virtual_machine_name
  location              = "Central India"
  resource_group_name   = azurerm_resource_group.myrg1.name
  network_interface_ids = [azurerm_network_interface.myvmnic.id]
  vm_size                 = "Standard_B1s"

  storage_os_disk {
    name              = "myOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

 storage_image_reference {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
  version   = "latest"  # Replace with a valid version available in your Azure environment
}

  os_profile {
    computer_name     =  var.computer_names[2]
    admin_username    = "adminuser"
    admin_password    = "Rockwell@6459"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "dev"
  }
}

data "azurerm_public_ip" "ip" {
  name                = azurerm_public_ip.publicip.name
  resource_group_name = azurerm_public_ip.publicip.resource_group_name
  depends_on          = [azurerm_virtual_machine.vm]
}

output "public_ip_address" {
  value = data.azurerm_public_ip.ip.ip_address
}
