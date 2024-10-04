#!/bin/bash

# check if the terraform.tfvars file exists
if [ -f ../terraform/terraform.tfvars ]; then
  # with green color check mark and message
  echo -e "\e[32m\xE2\x9C\x94 Terraform variables file found\e[0m"
  # source the file
  source ../terraform/terraform.tfvars
else
  # with red color x mark and the message
  echo -e "\e[31m\xE2\x9C\x98 Terraform variables file not found\e[0m"
  # finish the script
  echo "Exiting..."
  exit 0
fi

# load it 
source ../terraform/terraform.tfvars

# print the values of the variables with green color
echo -e "client_id=\033[0;32m$client_id\033[0m"
echo -e "client_secret=\033[0;32m$client_secret\033[0m"
echo -e "tenant_id=\033[0;32m$tenant_id\033[0m"
echo -e "subscription_id=\033[0;32m$subscription_id\033[0m"
echo -e "object_id=\033[0;32m$object_id\033[0m"
echo -e "location=\033[0;32m$location\033[0m"
echo -e "resource_group_name=\033[0;32m$resource_group_name\033[0m"
echo -e "project_name=\033[0;32m$project_name\033[0m"
echo -e "service_principal_name=\033[0;32m$service_principal_name\033[0m"

# show the RBAC for the service principal name
echo -e "\e[33m\xE2\x9A\xA0 Showing the RBAC for the service principal\e[0m"
az role assignment list --assignee $client_id --output table

# Fetch and display human-readable names of the resources
echo -e "\e[33m\xE2\x9A\xA0 Fetching human-readable names of the resources\e[0m"
assignments=$(az role assignment list --assignee $client_id --query "[].{role:roleDefinitionName, scope:scope}" -o tsv)
service_principal_name=$(az ad sp show --id $client_id --query "displayName" -o tsv)
echo -e "Service Principal Name: \033[0;32m$service_principal_name\033[0m"
while IFS=$'\t' read -r role scope; do
  resource_name=$(az resource show --ids $scope --query "name" -o tsv 2>/dev/null)
  if [ -z "$resource_name" ]; then
    resource_name="N/A"
  fi
  echo -e "Role: \033[0;32m$role\033[0m, Scope: \033[0;32m$scope\033[0m, Resource Name: \033[0;32m$resource_name\033[0m"
done <<< "$assignments"

# login to azure using the service principal
# warn that login with this credentials will reduce the capabilities of the azure cli with yellow color
echo -e "\e[33m\xE2\x9A\xA0 Logging in to Azure with service principal will reduce the capabilities of the Azure CLI\e[0m"
# ask for confirmation
read -p "Do you want to continue? (y/n) " -n 1 -r
echo
# if the answer is not y
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    # with red color x mark and message
    echo -e "\e[31m\xE2\x9C\x98 Azure login cancelled\e[0m"
    # finish the script
    echo "Exiting..."
    exit 0
fi
# az login --service-principal --username $client_id --password $client_secret --tenant $tenant_id 

# # check if the login was successful
# if [ $? -eq 0 ]; then
#     # with green color check mark and message
#     echo -e "\e[32m\xE2\x9C\x94 Logged in to Azure successfully\e[0m"
# else
#     # with red color x mark and message
#     echo -e "\e[31m\xE2\x9C\x98 Azure login failed\e[0m"
#     # finish the script
#     echo "Exiting..."
#     exit 0
# fi

export ARM_CLIENT_ID="$client_id"
export ARM_CLIENT_SECRET="$client_secret"
export ARM_SUBSCRIPTION_ID="$subscription_id"
export ARM_TENANT_ID="$tenant_id"
