# Resource Group
resource "azurerm_resource_group" "mario_rg" {
  name     = "mario-aks-rg"
  location = "eastus"
}

# Virtual Network
resource "azurerm_virtual_network" "mario_vnet" {
  name                = "mario-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.mario_rg.location
  resource_group_name = azurerm_resource_group.mario_rg.name
}

# Subnet
resource "azurerm_subnet" "mario_subnet" {
  name                 = "mario-subnet"
  resource_group_name  = azurerm_resource_group.mario_rg.name
  virtual_network_name = azurerm_virtual_network.mario_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "mario_aks" {
  name                = "AKS-CLOUD"
  location            = azurerm_resource_group.mario_rg.location
  resource_group_name = azurerm_resource_group.mario_rg.name
  dns_prefix          = "mario-aks"

  default_node_pool {
    name                = "nodecloud"
    vm_size             = "Standard_D2s_v3"
    vnet_subnet_id      = azurerm_subnet.mario_subnet.id
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 2
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  oidc_issuer_enabled = true

  tags = {
    Environment = "mario-game"
  }
}

# Grant AKS cluster (system) identity Network Contributor on the resource group
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_resource_group.mario_rg.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.mario_aks.identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster.mario_aks]
}

# Grant AKS kubelet identity Network Contributor on the resource group
resource "azurerm_role_assignment" "aks_kubelet_network_contributor" {
  scope                = azurerm_resource_group.mario_rg.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.mario_aks.kubelet_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.mario_aks]
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.mario_aks.kube_config_raw
  sensitive = true
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.mario_aks.name
}

output "resource_group" {
  value = azurerm_resource_group.mario_rg.name
}
