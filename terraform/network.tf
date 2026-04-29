resource "azurerm_resource_group" "cdn" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = var.environment_tag
    component   = "cdn-simulator"
  }
}

resource "azurerm_virtual_network" "cdn" {
  name                = "vnet-cdn-simulator"
  address_space       = ["10.100.0.0/16"]
  location            = azurerm_resource_group.cdn.location
  resource_group_name = azurerm_resource_group.cdn.name

  tags = azurerm_resource_group.cdn.tags
}

resource "azurerm_subnet" "edge" {
  name                 = "snet-edge"
  resource_group_name  = azurerm_resource_group.cdn.name
  virtual_network_name = azurerm_virtual_network.cdn.name
  address_prefixes     = ["10.100.1.0/24"]
}

resource "azurerm_public_ip" "edge" {
  name                = "pip-cdn-edge"
  location            = azurerm_resource_group.cdn.location
  resource_group_name = azurerm_resource_group.cdn.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = azurerm_resource_group.cdn.tags
}

resource "azurerm_network_security_group" "edge" {
  name                = "nsg-cdn-edge"
  location            = azurerm_resource_group.cdn.location
  resource_group_name = azurerm_resource_group.cdn.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.cdn.tags
}

resource "azurerm_network_interface" "edge" {
  name                = "nic-cdn-edge"
  location            = azurerm_resource_group.cdn.location
  resource_group_name = azurerm_resource_group.cdn.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.edge.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.edge.id
  }

  tags = azurerm_resource_group.cdn.tags
}

resource "azurerm_network_interface_security_group_association" "edge" {
  network_interface_id      = azurerm_network_interface.edge.id
  network_security_group_id = azurerm_network_security_group.edge.id
}
