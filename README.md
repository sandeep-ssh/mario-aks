# Super Mario on Azure Kubernetes Service (AKS) with Terraform

This project deploys a Super Mario game container on **Azure Kubernetes Service (AKS)** using Terraform.
It is a conversion of the original AWS EKS-based deployment.

---

## Architecture

| AWS (Original)               | Azure (Converted)                          |
|------------------------------|--------------------------------------------|
| AWS EKS Cluster              | Azure Kubernetes Service (AKS)             |
| IAM Roles & Policy Attachments | System-Assigned Managed Identity         |
| Default VPC + Public Subnets | Azure VNet + Subnet                        |
| EC2 t2.medium nodes          | Standard_B2s VMs                           |
| S3 Backend (terraform.tfstate) | Azure Blob Storage Backend               |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- An active Azure subscription

---

## Setup

### 1. Authenticate with Azure

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 2. Create the Terraform State Backend (one-time setup)

Before running Terraform, create the Azure Storage Account for remote state:

```bash
az group create --name mario-tfstate-rg --location australiaeast

az storage account create \
  --name mario12storageaccount \
  --resource-group mario-tfstate-rg \
  --location australiaeast \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name mario12storageaccount
```

### 3. Deploy the AKS Cluster

```bash
terraform init
terraform plan
terraform apply
```

### 4. Configure kubectl

```bash
az aks get-credentials \
  --resource-group mario-aks-rg \
  --name AKS-CLOUD
```

### 5. Deploy the Mario App

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### 6. Get the Public IP

```bash
kubectl get service mario-service
```

Wait until the `EXTERNAL-IP` column shows an IP address, then open it in your browser.

---

## Cleanup

```bash
kubectl delete -f deployment.yaml
kubectl delete -f service.yaml
terraform destroy
```

---

## Key Differences from AWS EKS Version

- **No manual IAM roles needed**: AKS uses a System-Assigned Managed Identity, which automatically gets the permissions it needs — replacing the 5 IAM roles/policy attachments in the original.
- **Integrated CNI**: Azure CNI is configured via `network_plugin = "azure"`, replacing the `AmazonEKS_CNI_Policy`.
- **Container Registry Access**: AKS can pull from public Docker Hub without extra credentials, just like EKS. For private ACR, attach it with `az aks update --attach-acr`.
- **State backend**: S3 is replaced with Azure Blob Storage using the `azurerm` backend.
# mario-aks
