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
  default       = "chris.green"
  description   = "User name"
}

variable "user_name2" {
  type          = string
  default       = "peter.williams"
  description   = "User name"
}

variable "user_name3" {
  type          = string
  default       = "sqladmin"
  description   = "User name"
}

variable "user_password1" {
  type          = string
  description   = "Password"
}

variable "user_password2" {
  type          = string
  description   = "Password"
}

variable "user_password3" {
  type          = string
  description   = "Password"
}

variable "resource_group_name" {
  type          = string
  default       = "Innovation"
  description   = "The name of the Resource Group"
}

variable "application_name" {
  type          = string
  default       = "InnovationApp"
  description   = "The name of the App Register"
}

variable "key_vault_name" {
  type          = string
  default       = "InnovationTeamKeyVault"
  description   = "The name of the Key Vault"
}

variable "automation_account_name" {
  type          = string
  default       = "InnovationAutomation"
  description   = "The name of the Automation Account"
}

variable "sql_server_name" {
  type          = string
  default       = "svrcustomerdb"
  description   = "The name of the SQL Server"
}

variable "sql_db_name" {
  type          = string
  default       = "CustomerPIIDB"
  description   = "The name of the SQL DB"
}


#############################################################################
# DATA
#############################################################################

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

#############################################################################
# PROVIDERS
#############################################################################

terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = "2.22.0"
    }
  }
}

provider "azuread" {
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
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

resource "azuread_user" "user2" {
  user_principal_name         = "${var.user_name2}@${var.domain}"
  display_name                = var.user_name2
  password                    = var.user_password2
  disable_password_expiration = true
  department                  = "Linux user"
}

resource "azuread_user" "user3" {
  user_principal_name         = "${var.user_name3}@${var.domain}"
  display_name                = var.user_name3
  password                    = var.user_password3
  disable_password_expiration = true
}


## APP / SPN ##
resource "azuread_application" "InnovationApp" {
  display_name    = var.application_name
}

resource "azuread_service_principal" "InnovationAppSPN" {
  application_id               = azuread_application.InnovationApp.application_id
}

## Key Vault ##
resource "azurerm_key_vault" "InnovationDeptKeyVault" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.innovation.location
  resource_group_name         = azurerm_resource_group.innovation.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Create",
    ]

    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set",
    ]

    storage_permissions = [
      "Backup", "Delete", "Get", "List", "Update", "Recover", "Restore",
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azuread_service_principal.InnovationAppSPN.object_id
    key_permissions = [
      "Get", "List",
    ]
    secret_permissions = [
      "Get", "List",
    ]
  }
}

resource "azurerm_key_vault_secret" "ForPW" {
  name          = "ForPW"
  value         = "${var.user_password2}"
  key_vault_id  = azurerm_key_vault.InnovationDeptKeyVault.id
  depends_on    = [azurerm_key_vault.InnovationDeptKeyVault]
}

## Automation Account ##
resource "azurerm_automation_account" "InnovationAutomationAccount" {
  name                = var.automation_account_name
  location            = azurerm_resource_group.innovation.location
  resource_group_name = azurerm_resource_group.innovation.name

  sku_name = "Basic"
}

resource "azurerm_automation_credential" "sa" {
  name                    = "sa"
  resource_group_name     = azurerm_resource_group.innovation.name
  automation_account_name = azurerm_automation_account.InnovationAutomationAccount.name
  username                = "sa@softwaresolutionsdons.com"
  password                = "gROzIH&L2Zu4Ya"
}

resource "azurerm_automation_credential" "sqladmin" {
  name                    = "sqladmin"
  resource_group_name     = azurerm_resource_group.innovation.name
  automation_account_name = azurerm_automation_account.InnovationAutomationAccount.name
  username                = "${var.user_name3}@${var.domain}"
  password                = "${var.user_password3}"
}

## SQL DB ##
resource "azurerm_mssql_server" "AzureSQLServer" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.innovation.name
  location                     = "East US"
  version                      = "12.0"
  administrator_login          = "${var.user_name3}@${var.domain}"
  administrator_login_password = "${var.user_password3}"

  azuread_administrator {
    login_username = "${var.user_name3}"
    object_id      = azuread_user.user3.id
    azuread_authentication_only = true
  }
}

resource "azurerm_mssql_firewall_rule" "SQLFirewallRule" {
  name                = "AlllowAzureServices"
  server_id           = azurerm_mssql_server.AzureSQLServer.id
  start_ip_address    = "X.X.X.X"
  end_ip_address      = "X.X.X.X"
}

resource "azurerm_mssql_database" "AzureSQLDB" {
  name                = var.sql_db_name
  server_id           = azurerm_mssql_server.AzureSQLServer.id
  collation           = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb         = 1
  sku_name            = "Basic"
  sample_name         = "AdventureWorksLT"
}

### AZURE ROLE AND ROLE ASSIGNMENT ###

## Directory Roles
resource "azuread_directory_role" "appAdmin" {
  display_name = "Application administrator"
}

resource "azuread_directory_role_member" "appAdminMembers" {
  role_object_id   = azuread_directory_role.appAdmin.object_id
  member_object_id = azuread_user.user1.id
}

## RBAC Roles
resource "azurerm_role_assignment" "ACKeyVault1" {
  scope                = azurerm_key_vault.InnovationDeptKeyVault.id
  role_definition_name = "Key Vault Reader"
  principal_id         = azuread_service_principal.InnovationAppSPN.object_id
}

resource "azurerm_role_assignment" "ACKeyVault2" {
  scope                = azurerm_key_vault.InnovationDeptKeyVault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.InnovationAppSPN.object_id
}

resource "azurerm_role_assignment" "ACAutomationAccount" {
  scope                = azurerm_automation_account.InnovationAutomationAccount.id
  role_definition_name = "Contributor"
  principal_id         = azuread_user.user2.id
}

resource "azurerm_role_assignment" "ACSQLServer" {
  scope                = azurerm_mssql_server.AzureSQLServer.id
  role_definition_name = "Reader"
  principal_id         = azuread_user.user3.id
}

## Conditional Access rules
resource "azuread_conditional_access_policy" "Linux" {
  display_name = "Linux Users"
  state        = "enabled"

  conditions {
    client_app_types    = ["all"]

    applications {
      included_applications = ["All"]
    }

    locations {
      included_locations = ["All"]
    }

    platforms {
      included_platforms = ["android", "iOS", "macOS", "windows", "windowsPhone"]
      excluded_platforms = ["linux"]
    }

    users {
      included_users = [azuread_user.user2.id]
    }
  }

  grant_controls {
    operator          = "AND"
    built_in_controls = ["block"]
  }
}

## Output
output "username" {
  value = "${var.user_name1}@${var.domain}"
}
output "password" {
  value = var.user_password1
}
