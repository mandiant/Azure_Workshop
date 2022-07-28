# Author: Roxana Kovaci
# Twitter: @RoxanaKovaci

#############################################################################
# VARIABLES
#############################################################################

variable "domain" {
  type          = string
  description   = "Domain name (for example: contoso.onmicrosoft.com)"
}

variable "user_name1" {
  type          = string
  default       = "katie.parkson"
  description   = "User name"
}

variable "user_password1" {
  type          = string
  description   = "Password"
}

variable "resource_group_name" {
  type          = string
  default       = "engineering"
  description   = "The name of the Resource Group"
}

variable "linuxvm_name" {
  type          = string
  default       = "LinuxVM"
  description   = "The name of the Linux VM"
}

variable "windowsvm_name" {
  type          = string
  default       = "WindowsVM"
  description   = "The name of the Windows VM"
}

variable "virtual_network_name" {
  type          = string
  default       = "vNetwork"
  description   = "The name of the virtual network"
}

variable "linuxvm_user" {
  type          = string
  default       = "azureuser"
  description   = "The name of the sudo user on Linux VM"
}

variable "windowsvm_user" {
  type          = string
  default       = "helen"
  description   = "The name of the local admin on the Windows VM"
}

variable "windowsvm_password" {
  type          = string
  description   = "The password of the local admin on the Windows VM"
}

variable "storage_account_name" {
  type          = string
  default       = "datamining01"
  description   = "The name of the Storage Account"
}

variable "container_name" {
  type          = string
  default       = "investment"
  description   = "The name of the Storage Container"
}

variable "share_name" {
  type          = string
  default       = "engineering-data"
  description   = "The name of the Storage File Share"
}


#############################################################################
# DATA
#############################################################################

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

#############################################################################
# PROVIDERS
#############################################################################

provider "azurerm" {
  features {}
}

provider "azuread" {
}


#############################################################################
# RESOURCES
#############################################################################

## Resource Group ##

resource "azurerm_resource_group" "innovation" {
  name     = var.resource_group_name
  location = "East US"
}

## AZURE AD USER ##

resource "azuread_user" "user1" {
  user_principal_name         = "${var.user_name1}@${var.domain}"
  display_name                = var.user_name1
  password                    = var.user_password1
  disable_password_expiration = true
}

## AZURE STORAGE ACCOUNT ##
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.innovation.name
  location                 = azurerm_resource_group.innovation.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "container-file" {
  name                   = "secret.txt"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
  source                 = "./secret.txt"
}

resource "azurerm_storage_share" "share" {
  name                 = var.share_name
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 50
}

resource "azurerm_storage_share_file" "share-file" {
  name             = "super-secret-file.txt"
  storage_share_id = azurerm_storage_share.share.id
  source           = "./super-secret-file.txt"
}

## AZURE LINUX VIRTUAL MACHINE ##
resource "azurerm_virtual_network" "vNet" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.innovation.location
  resource_group_name = azurerm_resource_group.innovation.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.innovation.name
  virtual_network_name = azurerm_virtual_network.vNet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "LinuxVMPublicIP" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.innovation.location
  resource_group_name = azurerm_resource_group.innovation.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"       
}

resource "azurerm_network_interface" "External" {
  name                = "ExternalNIC"
  location            = azurerm_resource_group.innovation.location
  resource_group_name = azurerm_resource_group.innovation.name

  ip_configuration {
    name                          = "external"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.LinuxVMPublicIP.id
  }
}

resource "azurerm_network_security_group" "NSG" {
    name                = "LinuxVMNSG"
    location            = azurerm_resource_group.innovation.location
    resource_group_name = azurerm_resource_group.innovation.name
}

resource "azurerm_network_interface_security_group_association" "NSGAssociation" {
    network_interface_id      = azurerm_network_interface.External.id
    network_security_group_id = azurerm_network_security_group.NSG.id
}

## AZURE Linux VM ##
resource "azurerm_linux_virtual_machine" "LinuxVM" {
  name                            = var.linuxvm_name
  resource_group_name             = azurerm_resource_group.innovation.name
  location                        = azurerm_resource_group.innovation.location
  size                            = "Standard_B2s"
  admin_username                  = var.linuxvm_user
  network_interface_ids           = [azurerm_network_interface.External.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("./id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type         = "SystemAssigned"
  }
}

resource "azurerm_virtual_machine_extension" "CommandLinux" {
  name                 = "customscript"
  virtual_machine_id   = azurerm_linux_virtual_machine.LinuxVM.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
      "commandToExecute": "sudo apt-get update && sudo apt-get upgrade && curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    }
  SETTINGS
}

## AZURE Windows VM ##
resource "azurerm_network_interface" "Internal1" {
  name                = "InternalNIC1"
  resource_group_name = azurerm_resource_group.innovation.name
  location            = azurerm_resource_group.innovation.location

  ip_configuration {
    name                          = "internal1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "WindowsVM" {
  name                  = var.windowsvm_name
  resource_group_name   = azurerm_resource_group.innovation.name
  location              = azurerm_resource_group.innovation.location
  size                  = "Standard_B2s"
  admin_username        = var.windowsvm_user
  admin_password        = var.windowsvm_password
  network_interface_ids = [azurerm_network_interface.Internal1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "21h1-pro"
    version   = "latest"
  }

  identity {
    type      = "SystemAssigned"
  }
}

resource "azurerm_virtual_machine_extension" "CommandWindows" {
  virtual_machine_id   = azurerm_windows_virtual_machine.WindowsVM.id
  name                 = "installscript"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  # NOTE: Script is executed from a cmd-shell, therefore escape " as \".
  #       Second, since value is json-encoded, escape \" as \\\".
  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -Command Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\\AzureCLI.msi"
    }
SETTINGS
}

## AZURE ROLES AND ROLES ASSIGNMENT ##
resource "azurerm_role_assignment" "ACBlob" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_user.user1.id
}

resource "azurerm_role_assignment" "ACStorage" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Reader"
  principal_id         = azuread_user.user1.id
}

resource "azurerm_role_assignment" "ACPublicIP" {
  scope                = azurerm_public_ip.LinuxVMPublicIP.id
  role_definition_name = "Reader"
  principal_id         = azuread_user.user1.id
}

resource "azurerm_role_assignment" "ACLinuxNSG" {
  scope                = azurerm_network_security_group.NSG.id
  role_definition_name = "Owner"
  principal_id         = azuread_user.user1.id
}

resource "azurerm_role_assignment" "ACShare1" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_windows_virtual_machine.WindowsVM.identity.0.principal_id
}

resource "azurerm_role_assignment" "ACWindowsVM" {
  scope                = azurerm_windows_virtual_machine.WindowsVM.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_linux_virtual_machine.LinuxVM.identity.0.principal_id
}

## Output
output "username" {
  value = "${var.user_name1}@${var.domain}"
}
output "password" {
  value = var.user_password1
}
