terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  terminal_ports = range(7681, 7701)
  terminal_users = [
    for index in range(1, 21) : format("participant%02d", index)
  ]
}

resource "azurerm_resource_group" "workshop" {
  name     = "${var.name_prefix}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "workshop" {
  name                = "${var.name_prefix}-vnet"
  location            = azurerm_resource_group.workshop.location
  resource_group_name = azurerm_resource_group.workshop.name
  address_space       = [var.vnet_address_space]
}

resource "azurerm_subnet" "workshop" {
  name                 = "${var.name_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.workshop.name
  virtual_network_name = azurerm_virtual_network.workshop.name
  address_prefixes     = [var.subnet_address_prefix]
}

resource "azurerm_network_security_group" "workshop" {
  name                = "${var.name_prefix}-nsg"
  location            = azurerm_resource_group.workshop.location
  resource_group_name = azurerm_resource_group.workshop.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.allowed_source_cidrs
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ttyd-terminals"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["7681-7700"]
    source_address_prefixes    = var.allowed_source_cidrs
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "workshop" {
  name                = "${var.name_prefix}-public-ip"
  location            = azurerm_resource_group.workshop.location
  resource_group_name = azurerm_resource_group.workshop.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "workshop" {
  name                = "${var.name_prefix}-nic"
  location            = azurerm_resource_group.workshop.location
  resource_group_name = azurerm_resource_group.workshop.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.workshop.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.workshop.id
  }
}

resource "azurerm_network_interface_security_group_association" "workshop" {
  network_interface_id      = azurerm_network_interface.workshop.id
  network_security_group_id = azurerm_network_security_group.workshop.id
}

resource "azurerm_linux_virtual_machine" "workshop" {
  name                = "${var.name_prefix}-host"
  location            = azurerm_resource_group.workshop.location
  resource_group_name = azurerm_resource_group.workshop.name
  size                = "Standard_D4s_v3"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.workshop.id
  ]

  # azurerm_linux_virtual_machine uses both flags to select the security type.
  # Keeping them disabled deploys the VM as Standard rather than Trusted Launch.
  secure_boot_enabled = false
  vtpm_enabled        = false

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init.sh", {
    terminal_ports = local.terminal_ports
    terminal_users = local.terminal_users
    ttyd_version   = var.ttyd_version
  }))
}
