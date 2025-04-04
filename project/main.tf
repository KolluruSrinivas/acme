terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.7.0"
    }
  }
}

provider "azurerm" {
  features {}
client_id = "c47228e8-ac5d-4406-ad0d-6c5751eb4821"
tenant_id = "ba61a0f0-dce9-4958-bf67-58e0ff045ad2"
client_secret = "U_g8Q~cKHFFYXf2HzI0VrWhIMiKbUZozKwrM0bfN"
subscription_id = "8258e319-97da-4600-a76c-49edbf93df29"

}



resource "azurerm_resource_group" "rg1" {
  name     = "acmerg"
  location = "East US"
}

# Crrating Virtual network 

resource "azurerm_virtual_network" "vnet1" {
    name = "acme-Vnet"
    location = var.location
    resource_group_name = azurerm_resource_group.rg1.name
    address_space       = ["10.0.0.0/16"]
  
}

# Creating subnets for App and DB

resource "azurerm_subnet" "app_subnet" {
    name  = "acme-app-subnet"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]

}

resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "middleware_subnet" {
  name = "middleware_subnet"    
    resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.3.0/24"]
}


# creating AppServices 

resource "azurerm_service_plan" "plan" {
    name = "acme-app-plan"
    location = var.location
    resource_group_name = azurerm_resource_group.rg1.name
    os_type = "Windows"
    sku_name= "P1v2"
   
}

    

# Creating Backend for Frontend 

resource "azurerm_app_service" "backend_api" {
  name                = "backend-api-04032025"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg1.name
  app_service_plan_id = azurerm_service_plan.plan.id
}

resource "azurerm_app_service" "middleware_api" {
  name                = "acme-middleware-api"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg1.name
  app_service_plan_id = azurerm_service_plan.plan.id
}

# Creating Azure SQl Database

resource "azurerm_mssql_server" "sql_server" {
    name =  "acme04032026-sql-server"
  location = var.location
  resource_group_name =  azurerm_resource_group.rg1.name
  version ="12.0"
  administrator_login = "sqladmin"
  administrator_login_password = "Srinivas@1983"
}

resource "azurerm_mssql_database" "sql_database" {
    name = "acme-database"
    server_id = azurerm_mssql_server.sql_server.id
    collation = "SQL_Latin1_General_CP1_CI_AS"
    max_size_gb = 5
    sku_name = "S0"
    transparent_data_encryption_enabled = true

}

resource "azurerm_key_vault" "keyvault" {

    name = "acmeKV04032025"
    location = var.location
    resource_group_name = azurerm_resource_group.rg1.name
    sku_name = "standard"
    tenant_id = "ba61a0f0-dce9-4958-bf67-58e0ff045ad2"
  
}


# resource "azurerm_mssql_server_transparent_data_encryption" "tde" {
#   server_id       = azurerm_mssql_server.sql_server.id
#   key_vault_key_id = azurerm_key_vault_key.cmk.id
#} 

# Creating Endpoints 

resource "azurerm_private_endpoint" "sql_private_endpoint" {
    name = "sql-private-endpoint1"
    location = var.location
    resource_group_name = azurerm_resource_group.rg1.name
    subnet_id = azurerm_subnet.db_subnet.id

    private_service_connection {
      name = "sql-private-link"
      private_connection_resource_id = azurerm_mssql_server.sql_server.id
      is_manual_connection = false
      subresource_names = [ "sqlserver" ]
    }

    depends_on = [azurerm_subnet.db_subnet, azurerm_mssql_server.sql_server]
  
}

resource "azurerm_private_dns_zone" "private_dns" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.rg1.name
}


resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
    name = "dns-vnet-link"
    resource_group_name = azurerm_resource_group.rg1.name
    private_dns_zone_name = azurerm_private_dns_zone.private_dns.name
    virtual_network_id = azurerm_virtual_network.vnet1.id
    
}

