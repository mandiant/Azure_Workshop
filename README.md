# Azure Red Team Attack and Detect Workshop

This is a vulnerable-by-design Azure lab containing 2 x attack paths with common misconfigurations. These vulnerabilities are intended to represent those found in live production environments and the attack vectors are intended to be as realistic as possible to real Threat Actors TTPs. If you would like to see what detections and alerts these attack path vectors are causing, I recommend signing up for a Microsoft E5 trial which has Microsoft Defender for Cloud and Azure AD premium P2 plan. Links for signing up to an Azure Developer account can be found in the resources.txt file.

Author - Roxana Kovaci (@RoxanaKovaci)

## Requirements
- Azure tenant
- Azure CLI
- Terraform version 1.2.2 or above
- Azure User with Global Admin role in the AAD tenant
- add your external IP on lines 248-249 in kc1.tf

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

cd ../kc2

terraform init
terraform validate

terraform plan -out kc2.tfplan
terraform apply kc2.tfplan
```

## Get started
- the entry point for each kill-chain is user1. To get the initial user's credentials, run the following query:
```
terraform output
```

## Kill-Chain objectives and other resources
Kill-Chain #1:

- Objective: Gain access to the Customers PII data.

- Solutions: The full attack path solutions can be found in kc1/kc1_solution.txt

Kill-Chain #2:

- Objective: Gain access to the super secret file.

- Solutions: The full attack path solutions can be found in kc2/kc2_solution.txt

Each kill-chain has in its folder the Terraform script (and other pre-reqs files needed for deployment) and the solutions to the challenges.

Other resources and useful links to learn more can be found in resources.txt file.

## Clean up
After finishing with each kill-chain scenario, you can remove all resources previously added in your tenant:
```
az login

cd kc1
terraform destroy

cd ../kc2
terraform destroy
```
