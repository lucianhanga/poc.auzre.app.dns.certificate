#!/bin/bash

# Function to show a spinner
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinner='|/-\'
    while [ -d /proc/$pid ]; do
        for i in $(seq 0 3); do
            printf "\r${spinner:$i:1} Deleting resource group..."
            sleep $delay
        done
    done
    printf "\r"
}

# check if you are logged in to GitHub using gh command
# if not logged in, then prompt the user to login
gh auth status > /dev/null
if [ $? -eq 1 ]; then
    # with red color strting with the x mark and the message not logged in to github
    echo -e "\e[31m\xE2\x9C\x98 Not logged in to GitHub\e[0m"
    exit 1
else
    # with green color -  check mark and the message logged in to github
    echo -e "\e[32m\xE2\x9C\x94 Logged in to GitHub\e[0m"
fi

# make sure that you are loogged in to azure with credentials 
# which have access to create resource groups, and service principals
# and give the required permissions to the service principal

# step1 check if the user is logged in
az account show > /dev/null 2>&1
# if errr code is 1 then user is not logged in
if [ $? -eq 1 ]; then
    # with red color strting with the x mark and the message not logged in to azure
    echo -e "\e[31m\xE2\x9C\x98 Not logged in to azure\e[0m"
    exit 1
else
    # with green color -  check mark and the message logged in to azure
    echo -e "\e[32m\xE2\x9C\x94 Logged in to azure\e[0m"
fi

# step2 check if the user has contributor access to the subscription
az role assignment list --include-inherited --assignee $(az ad signed-in-user show --query id -o tsv) --role Contributor > /dev/null
# if error code is 1 then user does not have contributor access
if [ $? -eq 1 ]; then
    # with red color x mark and the message
    echo -e "\e[31m\xE2\x9C\x98 You do not have contributor access to the subscription\e[0m"
    exit 1
else
    # with green color checked mark and the message
    echo -e "\e[32m\xE2\x9C\x94 You have contributor access to the subscription\e[0m"
fi

# step 3 check if you have User Manager role in the subscription
az role assignment list --include-inherited --assignee $(az ad signed-in-user show --query id -o tsv) --role "User Access Administrator" > /dev/null
# if errr code is 1 then user does not have User Access Administrator access
if [ $? -eq 1 ]; then
    # with red color x mark and the message
    echo -e "\e[31m\xE2\x9C\x98 You do not have User Access Administrator access to the subscription\e[0m"
    exit 1
else
    # with green color checked mark and the message
    echo -e "\e[32m\xE2\x9C\x94 You have User Access Administrator access to the subscription\e[0m"
fi

# step 4 check if the user has access to create service principals
az ad sp create-for-rbac --name "testsp" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    # with green color checked mark and the message
    echo -e "\e[32m\xE2\x9C\x94 You have Service Principal creation rights\e[0m"
    # delte the service principal
    az ad sp delete --id $(az ad sp list --filter "displayName eq 'testsp'" --query "[0].appId" -o tsv) > /dev/null 2>&1
else
    # with red color x mark and the message
    echo -e "\e[31m\xE2\x9C\x98 No rights to create a Service principal\e[0m"
fi

# get all the resources from the ../terraform/terraform.tfstate file
if [ -f ../terraform/terraform.tfvars ]; then
  # with green color checked mark and the message
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

# print the values of the variables with green color
echo -e "client_id=\033[0;32m$client_id\033[0m"
echo -e "client_secret=\033[0;32m$client_secret\033[0m"
echo -e "tenant_id=\033[0;32m$tenant_id\033[0m"
echo -e "subscription_id=\033[0;32m$subscription_id\033[0m"
echo -e "object_id=\033[0;32m$object_id\033[0m"
echo -e "location=\033[0;32m$location\033[0m"
echo -e "resource_group_name=\033[0;32m$resource_group_name\033[0m"
echo -e "project_name=\033[0;32m$project_name\033[0m"

# check if the resource group exists
az group show --name $resource_group_name > /dev/null 2>&1
# if the groupd does not exist print with yellow color and a yellow triangle
if [ $? -ne 0 ]; then
    # with yellow color and a yellow triangle and the message
    echo -e "\e[33m\xE2\x9A\xA0 Resource group does not exist\e[0m"
    echo -e "\e[33m  All azure resources were deprovisioned.\e[0m"
else
  # Start resource group deletion in background
  az group delete --name $resource_group_name --yes > /dev/null 2>&1 &
  delete_pid=$!

  # Show spinner while deletion is in progress
  show_spinner $delete_pid

  # Wait for the deletion process to complete
  wait $delete_pid

  # Check the result of the deletion process
  if [ $? -eq 0 ]; then
      # With green color check mark and message
      echo -e "\e[32m\xE2\x9C\x94 Resource group deleted successfully\e[0m"
  else
      # With red color X mark and message
      echo -e "\e[31m\xE2\x9C\x98 Resource group deletion failed\e[0m"
  fi
fi

# check if the service principal exists based on its object id
az ad sp show --id $object_id > /dev/null 2>&1
# if the service principal does not exist print with yellow color and a yellow triangle
if [ $? -ne 0 ]; then
    # with yellow color and a yellow triangle and the message
    echo -e "\e[33m\xE2\x9A\xA0 Service principal does not exist\e[0m"
    echo -e "\e[33m  All azure resources were deprovisioned.\e[0m"
else
  # Start service principal deletion in background
  az ad sp delete --id $object_id > /dev/null 2>&1 &
  delete_pid=$!

  # Show spinner while deletion is in progress
  show_spinner $delete_pid

  # Wait for the deletion process to complete
  wait $delete_pid

  # Check the result of the deletion process
  if [ $? -eq 0 ]; then
      # With green color check mark and message
      echo -e "\e[32m\xE2\x9C\x94 Service principal deleted successfully\e[0m"
  else
      # With red color X mark and message
      echo -e "\e[31m\xE2\x9C\x98 Service principal deletion failed\e[0m"
  fi
fi

# check if the ".env" file exists
if [ -f .env ]; then
  # with green color checked mark and the message
  echo -e "\e[32m\xE2\x9C\x94 .env file found\e[0m"
  # warn that now the github token will changed and has only read access on the source code
  echo -e "\e[33m\xE2\x9A\xA0 GitHub token will be changed to read-only access\e[0m"
  source .env
  echo -e "GITHUB_TOKEN=\033[0;32m$GITHUB_TOKEN\033[0m"
else
  # with red color x mark and the message
  echo -e "\e[31m\xE2\x9C\x98 .env file not found\e[0m"
  # finish the script
  echo "Exiting..."
  exit 0
fi

# cleanup the GitHub Actions secrets and variables  
echo -e "Cleaning up GitHub Actions secrets and variables"
gh secret delete AZURE_CLIENT_ID
gh secret delete AZURE_CLIENT_SECRET
gh secret delete AZURE_TENANT_ID
gh secret delete AZURE_SUBSCRIPTION_ID
gh secret delete AZURE_CREDENTIALS
gh secret delete PAT_TOKEN

gh variable delete AZURE_LOCATION
gh variable delete AZURE_GROUP_NAME
gh variable delete PROJECT_NAME

# message that all were cleaned up
echo -e "\e[32m\xE2\x9C\x94 All GitHub Actions secrets and variables were cleaned up\e[0m"

# delete the terraform.tfvars file
rm ../terraform/terraform.tfvars
echo -e "\e[32m\xE2\x9C\x94 Terraform variables file deleted\e[0m"
