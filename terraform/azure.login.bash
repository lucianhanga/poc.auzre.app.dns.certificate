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

# login to azure using the service principal
az login --service-principal --username $client_id --password $client_secret --tenant $tenant_id 

# check if the login was successful
if [ $? -eq 0 ]; then
    # with green color check mark and message
    echo -e "\e[32m\xE2\x9C\x94 Logged in to Azure successfully\e[0m"
else
    # with red color x mark and message
    echo -e "\e[31m\xE2\x9C\x98 Azure login failed\e[0m"
    # finish the script
    echo "Exiting..."
    exit 0
fi

