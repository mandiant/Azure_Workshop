# Azure Red Team Attack and Detect Workshop
This is a vulnerable-by-design Azure lab, containing 2 x attack paths with common misconfigurations. 

Each kill-chain has in its folder the Terraform script (and other pre-reqs files needed for deployment) as well as the solutions to the challenges.

## Requirements
- Azure tenant
- Azure CLI
- Terafform version 1.2.2 or above
- Azure User with Global Admin privileges in the AAD tenant

## Global changes needed in the Terraform scripts before deployment
- login as GA on your Azure tenant via AZ CLI
- add tenant domain name on line 7 on both kc1.tf and kc2.tf

### KC1
- add your external IP for MSSQL firewall on line 253-254

## Run the Terraform scripts 
```
terraform init
terraform validate

terraform plan -out kc1.tfplan
terraform apply kc1.tfplan
