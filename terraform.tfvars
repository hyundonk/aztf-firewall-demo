# input variables 

prefix                = "demo"
resource_group_name   = "deleteme-firewall"
location              = "koreacentral"

networking_object1                 = {
  vnet = {
      name                = "-firewall-vnet"
      address_space       = ["10.10.0.0/16"]
      dns                 = []
  }
  specialsubnets = {
    AzureFirewallSubnet   = {
      name                = "AzureFirewallSubnet"
      cidr                = "10.10.2.0/24"
      service_endpoints   = []
    },
  }

  subnets = {
    frontend   = {
      name                = "frontend"
      cidr                = "10.10.0.0/24"
      service_endpoints   = []
      nsg_name            = "frontend"
    },
    backend   = {
      name                = "backend"
      cidr                = "10.10.1.0/24"
      service_endpoints   = []
      nsg_name            = "backend"
    }
  }
}

pip_jumpbox = {
  0               = {
    name          = "jumpboxvm-pip"
  }
}

pip_firewall = {
  0               = {
    name          = "firewall-pip"
  }
}

jumpbox  = {
  name          = "jumpbox"

  vm_num        = 1
  vm_size       = "Standard_D2s_v3"
    
  subnet_ip_offset  = 4

  vm_publisher      = "MicrosoftWindowsServer"
  vm_offer          = "WindowsServer"
  vm_sku            = "2016-Datacenter"
  vm_version        = "latest"
}
 

vm  = {
  name          = "testvm"

  vm_num        = 1
  vm_size       = "Standard_D4s_v3"
    
  subnet_ip_offset  = 4

  vm_publisher      = "MicrosoftWindowsServer"
  vm_offer          = "WindowsServer"
  vm_sku            = "2016-Datacenter"
  vm_version        = "latest"
}
 

