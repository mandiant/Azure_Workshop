# Azure Workshop delivered at SteelCon - July 2022

## Global changes needed before deploying in your won Azure tenant
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
```
