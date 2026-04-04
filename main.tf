# Resource Group (equivalent to AWS account/region scoping)
resource "azurerm_resource_group" "mario_rg" {
  name     = "mario-aks-rg"
  location = "australiaeast" # Equivalent to ap-south-1; change to your preferred Azure region
}

# Virtual Network (equivalent to AWS default VPC)
resource "azurerm_virtual_network" "mario_vnet" {
  name                = "mario-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.mario_rg.location
  resource_group_name = azurerm_resource_group.mario_rg.name
}

# Public Subnet (equivalent to aws_subnets.public)
resource "azurerm_subnet" "mario_subnet" {
  name                 = "mario-subnet"
  resource_group_name  = azurerm_resource_group.mario_rg.name
  virtual_network_name = azurerm_virtual_network.mario_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# AKS Cluster (equivalent to aws_eks_cluster + aws_eks_node_group + all IAM roles/policies)
# Note: AKS manages its own identity and node permissions automatically —
# no manual IAM role/policy attachments are needed (unlike EKS).
resource "azurerm_kubernetes_cluster" "mario_aks" {
  name                = "AKS-CLOUD"
  location            = azurerm_resource_group.mario_rg.location
  resource_group_name = azurerm_resource_group.mario_rg.name
  dns_prefix          = "mario-aks"

  default_node_pool {
    name           = "nodecloud"      # Equivalent to node_group_name = "Node-cloud"
    node_count     = 1                # Equivalent to desired_size = 1
    vm_size        = "Standard_B2s"  # Equivalent to t2.medium (~2 vCPU, 4GB RAM)
    vnet_subnet_id = azurerm_subnet.mario_subnet.id

    # Auto-scaling equivalent to scaling_config { min_size=1, max_size=2 }
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 2
  }

  # System-assigned managed identity replaces all EKS IAM roles:
  # - eks-cluster-cloud (AmazonEKSClusterPolicy)
  # - eks-node-group-cloud (AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy, AmazonEC2ContainerRegistryReadOnly)
  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure" # Azure CNI — equivalent to AmazonEKS_CNI_Policy
    load_balancer_sku = "standard"
  }

  tags = {
    Environment = "mario-game"
  }
}

# Output kubeconfig for use with kubectl
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
