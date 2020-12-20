locals {
  resource_group_name   = var.resource_group_name
  location              = var.location
  admin_username        = "usernamehere"
  admin_password        = "userpasswordhere"
}


resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
}

module "virtual_network" {
  source  = "github.com/hyundonk/terraform-azurerm-caf-virtual-network"

  prefix              = "demo"

  virtual_network_rg  = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  networking_object   = var.networking_object1

  tags            = {}
}

module "pip_jumpbox" {
  source                            = "git://github.com/hyundonk/aztf-module-pip.git"

  prefix                            = "demo"
  services                          = var.pip_jumpbox

  location                          = azurerm_resource_group.rg.location
  rg                                = azurerm_resource_group.rg.name

  tags                              = {}
}

module "pip_firewall" {
  source                            = "git://github.com/hyundonk/aztf-module-pip.git"

  prefix                            = "demo"
  services                          = var.pip_firewall

  location                          = azurerm_resource_group.rg.location
  rg                                = azurerm_resource_group.rg.name

  tags                              = {}
}

module "jumpbox" {
  source                            = "git://github.com/hyundonk/aztf-module-vm.git"
  location                          = azurerm_resource_group.rg.location
  resource_group_name               = azurerm_resource_group.rg.name

  instances                         = var.jumpbox
  
  subnet_id                         = module.virtual_network.subnet_ids_map["frontend"]
  subnet_prefix                     = module.virtual_network.subnet_prefix_map["frontend"]

  admin_username                    = local.admin_username
  admin_password                    = local.admin_password

  public_ip_id                      = module.pip_jumpbox.public_ip.0.id
}

module "vm" {
  source                            = "git://github.com/hyundonk/aztf-module-vm.git"
  location                          = azurerm_resource_group.rg.location
  resource_group_name               = azurerm_resource_group.rg.name

  instances                         = var.vm
  
  subnet_id                         = module.virtual_network.subnet_ids_map["backend"]
  subnet_prefix                     = module.virtual_network.subnet_prefix_map["backend"]

  admin_username                    = local.admin_username
  admin_password                    = local.admin_password
}

resource "azurerm_firewall" "example" {
  name                = "testfirewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.virtual_network.subnet_ids_map["AzureFirewallSubnet"]
    public_ip_address_id = module.pip_firewall.public_ip.0.id
  }
}

module "route_table_to_firewall" {
  source                            = "git://github.com/hyundonk/aztf-module-rt.git"

  name                              = "demo-rt-to-firewall"
  location                          = azurerm_resource_group.rg.location
  rg                                = azurerm_resource_group.rg.name

  routes                            = {
    0             = {
      name                    = "route-to-internet"
      address_prefix          = "0.0.0.0/0"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = azurerm_firewall.example.ip_configuration[0].private_ip_address
    }
  }
  tags                              = {}
}

resource "azurerm_subnet_route_table_association" "backend" {
  subnet_id       = module.virtual_network.subnet_ids_map["backend"]
  route_table_id  = module.route_table_to_firewall.id
}

resource "azurerm_firewall_application_rule_collection" "example" {
  name                = "testcollection"
  azure_firewall_name = azurerm_firewall.example.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "testrule"

    source_addresses = [
      module.virtual_network.subnet_prefix_map["backend"]
    ]

    target_fqdns = [
      "*",
    ]

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

