# main.tf - Infraestructura como Código para Azure
# Proyecto DevOps - Jefferson Zamora

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. GRUPO DE RECURSOS
resource "azurerm_resource_group" "rg" {
  name     = "terraform-jefferson-rg"
  location = "West US 2"
}


# 2. RED VIRTUAL (VNet)
resource "azurerm_virtual_network" "vnet" {
  name                = "terraform-jefferson-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}


# 3. SUBNET
resource "azurerm_subnet" "subnet" {
  name                 = "terraform-jefferson-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


# 4. IP PÚBLICA
resource "azurerm_public_ip" "public_ip" {
  name                = "terraform-jefferson-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}


# 5. GRUPO DE SEGURIDAD (FIREWALL - NSG)
resource "azurerm_network_security_group" "nsg" {
  name                = "terraform-jefferson-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


# 6. INTERFAZ DE RED (NIC)
resource "azurerm_network_interface" "nic" {
  name                = "terraform-jefferson-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Asociar el NSG a la NIC
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# 7. MÁQUINA VIRTUAL (VM)
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "terraform-jefferson-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"
  admin_password      = "ProyectoDevops2026!"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22.04-LTS"
    version   = "latest"
  }

  tags = {
    environment = "devops"
    project     = "jefferson-devops"
    managed_by  = "terraform"
  }
}


# 8. OUTPUTS (mostrar resultados)
output "public_ip" {
  description = "IP pública de la VM"
  value       = azurerm_public_ip.public_ip.ip_address
}

output "vm_name" {
  description = "Nombre de la VM"
  value       = azurerm_linux_virtual_machine.vm.name
}

output "resource_group" {
  description = "Nombre del grupo de recursos"
  value       = azurerm_resource_group.rg.name
}
