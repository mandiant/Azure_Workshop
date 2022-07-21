# Azure Red Team Attack and Detect Workshop
This is a vulnerable-by-design Azure lab, containing 2 x attack paths with common misconfigurations. If you would like to see what alerts your malicious actions are causing, recommend signing up for a Microsoft E5 trial which has Microsoft Defender for Cloud as well as Azure AD premium P2 plan.

Each kill-chain has in its folder the Terraform script (and other pre-reqs files needed for deployment) as well as the solutions to the challenges.

## Requirements
- Azure tenant
- Azure CLI
- Terafform version 1.2.2 or above
- Azure User with Global Admin role in the AAD tenant

## Global changes needed in the Terraform scripts before deployment
- login as GA on your Azure tenant via AZ CLI
- add tenant domain name on line 7 on both kc1.tf and kc2.tf

## Deployment
```
az login
git clone https://github.com/mandiant/Azure_Workshop.git
cd Azure_Workshop
cd kc1

terraform init
terraform validate

terraform plan -out kc1.tfplan
terraform apply kc1.tfplan
```

## Get started
- to get the initial user's credentials, run the following query:
```
terraform output --json
```
- use username.value and password.value.

