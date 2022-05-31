#Define providers used
provider "azurerm" {
  features {} #This is required for v2 of the provider even if empty or plan will fail
}

#Data section
data "azurerm_resource_group" "rg" {
  name = "RG-TFTest"
}

#Resource section
resource "azurerm_virtual_network" "rg" {
  name                = "rg-network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}
resource "azurerm_subnet" "rg" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.rg.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_network_interface" "rg" {
  count               = 2
  name                = "TFTest-VM-${count.index}-NIC"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.rg.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_windows_virtual_machine" "rg" {
  count               = 2
  name                = "TFTest-VM-${count.index}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "tftadmin"
  admin_password      = "Pa55word!@"
  network_interface_ids = [
    azurerm_network_interface.rg.*.id[count.index],
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}