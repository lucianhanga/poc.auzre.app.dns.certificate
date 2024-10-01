#!/bin/bash


# Function to show usage
usage() {
  echo "Usage: $0 --project <name> --location <location> --group <resource-group-name> --sp <service-principal-name> --regenerate-secret"
  exit 1
}


# check if the ".env" file exists
if [ -f .env ]; then
  # with green color checked mark and the message
  echo -e "\e[32m\xE2\x9C\x94 .env file found\e[0m"
  # warn that now the github token will changed and has only read access on the source code
  echo -e "\e[33m\xE2\x9A\xA0 GitHub token will be changed to read-only access\e[0m"
  # old github token
  echo -e "old GITHUB_TOKEN=\033[0;31m$GITHUB_TOKEN\033[0m"
  # source the .env file  
  source .env
  echo -e "new GITHUB_TOKEN=\033[0;32m$GITHUB_TOKEN\033[0m"
else
  # with red color x mark and the message
  echo -e "\e[31m\xE2\x9C\x98 .env file not found\e[0m"
  # finish the script
  echo "Exiting..."
  exit 0
fi


# Initialize variables
LOCATION=""
RESOURCE_GROUP=""
SERVICE_PRINCIPAL=""
REGENERATE_SECRET="false"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --project) PROJECT="$2"; shift ;;
    --location) LOCATION="$2"; shift ;;
    --group) RESOURCE_GROUP="$2"; shift ;;
    --sp) SERVICE_PRINCIPAL="$2"; shift ;;
    --regenerate-secret) REGENERATE_SECRET="true";;
    *) echo "Unknown parameter: $1"; usage ;;
  esac
  shift
done

# check if the project name is provided
if [ -z "$PROJECT" ]; then
    # with red color x mark and the message
    echo -e "\e[31m\xE2\x9C\x98 Project name is required\e[0m"
    usage
else
    # with green color checked mark and the message
    echo -e "\e[32m\xE2\x9C\x94 Project name: $PROJECT\e[0m"
fi


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
az account show > /dev/null
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
az role assignment list --include-inherited --assignee $(az account show --query user.name -o tsv) --role Contributor > /dev/null
# if errr code is 1 then user does not have contributor access
if [ $? -eq 1 ]; then
    # with red color x mark and the message
    echo -e "\e[31m\xE2\x9C\x98 You do not have contributor access to the subscription\e[0m"
    exit 1
else
    # with green color checked mark and the message
    echo -e "\e[32m\xE2\x9C\x94 You have contributor access to the subscription\e[0m"
fi

# step 3 check if you have User Manager role in the subscription
az role assignment list --include-inherited --assignee $(az account show --query user.name -o tsv) --role "User Access Administrator" > /dev/null
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

# if the location is not provided as argument, prompt the user
if [ -z "$LOCATION" ]; then
  read -p "Please enter the location: " LOCATION
  if [ -z "$LOCATION" ]; then
    echo "Location cannot be empty."
    usage
  fi
fi

# If resource group name is not provided as argument, prompt the user
if [ -z "$RESOURCE_GROUP" ]; then
  read -p "Please enter the resource group name: " RESOURCE_GROUP
  if [ -z "$RESOURCE_GROUP" ]; then
    echo "Resource group name cannot be empty."
    usage
  fi
fi

echo "Creating resource group: $RESOURCE_GROUP"
# check if the group exists
az group show --name $RESOURCE_GROUP > /dev/null 2>&1
if [ $? -eq 0 ]; then
    # with yellow color and a yellow triangle and the message
    echo -e "\e[33m\xE2\x9A\xA0 Resource group already exists\e[0m"
else
    # create the group
    az group create --name $RESOURCE_GROUP --location eastus > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        # with green color checked mark and the message
        echo -e "\e[32m\xE2\x9C\x94 Resource group created successfully\e[0m"
    else
        # with red color x mark and the message
        echo -e "\e[31m\xE2\x9C\x98 Resource group creation failed\e[0m"
    fi
fi

# If service principal name is not provided as argument, prompt the user
if [ -z "$SERVICE_PRINCIPAL" ]; then
  read -p "Please enter the service principal name: " SERVICE_PRINCIPAL
  if [ -z "$SERVICE_PRINCIPAL" ]; then
    echo "Service principal name cannot be empty."
    usage
  fi
fi

echo "Creating service principal: $SERVICE_PRINCIPAL"
# check if the service principal exists
SP_EXISTS=$(az ad sp list --filter "displayName eq '$SERVICE_PRINCIPAL'" --query "length([])" -o tsv)
if [ "$SP_EXISTS" -gt 0 ]; then
    # with yellow color and a yellow triangle and the message
    echo -e "\e[33m\xE2\x9A\xA0 Service principal already exists\e[0m"
    if [ "$REGENERATE_SECRET" == "true" ]; then
        # generate a new secret for the service principal and save the values in the variables
        SP_JSON=$(az ad sp credential reset --id $(az ad sp list --display-name $SERVICE_PRINCIPAL --query "[0].appId" -o tsv)  -o json 2>/dev/null)
        echo $SP_JSON
        # echo the values of the variables  
        if [ $? -eq 0 ]; then
            # with green color checked mark and the message
            echo -e "\e[32m\xE2\x9C\x94 Service principal secret regenerated successfully\e[0m"
        else
            # with red color x mark and the message
            echo -e "\e[31m\xE2\x9C\x98 Service principal secret regeneration failed\e[0m"
        fi
    else
        # with yellow color and a yellow triangle and the message
        echo -e "\e[33m   --regenerate-secret to regenerate the service principal secret\e[0m"
        # finish the script
        echo "No modifications done to the service principal and the local files and GitHub secrets"
        echo "Exiting..."
        exit 0
    fi
else
    # create the service principal
    SP_JSON=$(az ad sp create-for-rbac --name $SERVICE_PRINCIPAL -o json)
    # echo the values of the variables
    echo $SP_JSON
    if [ $? -eq 0 ]; then
        # with green color checked mark and the message
        echo -e "\e[32m\xE2\x9C\x94 Service principal created successfully\e[0m"
    else
        # with red color x mark and the message
        echo -e "\e[31m\xE2\x9C\x98 Service principal creation failed\e[0m"
        echo "Exiting..."
        exit 0
    fi
fi

# give the service principal contributor access to the subscription
az role assignment create \
    --role Contributor \
    --assignee $(az ad sp list --display-name $SERVICE_PRINCIPAL --query "[0].appId" -o tsv) \
    --scope /subscriptions/$(az account show --query id -o tsv) > /dev/null 2>&1
if [ $? -eq 0 ]; then
    # with green color checked mark and the message
    echo -e "\e[32m\xE2\x9C\x94 Service principal has Contributor access to the subscription\e[0m"
else
    # with red color x mark and the message
    echo -e "\e[31m\xE2\x9C\x98 Service principal does not have Contributor access to the subscription\e[0m"
fi
# give the service principal User Access Administrator access to the group 
az role assignment create \
    --role "User Access Administrator" \
    --assignee $(az ad sp list --display-name $SERVICE_PRINCIPAL --query "[0].appId" -o tsv) \
    --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP > /dev/null 2>&1
if [ $? -eq 0 ]; then
    # with green color checked mark and the message
    echo -e "\e[32m\xE2\x9C\x94 Service principal has User Access Administrator access to the resource group\e[0m"
else
    # with red color x mark and the message
    echo -e "\e[31m\xE2\x9C\x98 Service principal does not have User Access Administrator access to the resource group\e[0m"
fi

# get the ObjectId of the service principal
SP_OBJECT_ID=$(az ad sp list --display-name $SERVICE_PRINCIPAL --query "[0].id" -o tsv)

# extract the values from the json and save them in the variables
AZURE_CLIENT_ID=$(echo $SP_JSON | jq -r .appId)
AZURE_CLIENT_SECRET=$(echo $SP_JSON | jq -r .password)
AZURE_TENANT_ID=$(echo $SP_JSON | jq -r .tenant)
AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
# save the values in the terraform.tfvars file in the ../terraform folder
echo "client_id=\"$AZURE_CLIENT_ID\"" > ../terraform/terraform.tfvars
echo "client_secret=\"$AZURE_CLIENT_SECRET\"" >> ../terraform/terraform.tfvars
echo "tenant_id=\"$AZURE_TENANT_ID\"" >> ../terraform/terraform.tfvars
echo "subscription_id=\"$AZURE_SUBSCRIPTION_ID\"" >> ../terraform/terraform.tfvars
echo "object_id=\"$SP_OBJECT_ID\"" >> ../terraform/terraform.tfvars
echo "location=\"$LOCATION\"" >> ../terraform/terraform.tfvars
echo "resource_group_name=\"$RESOURCE_GROUP\"" >> ../terraform/terraform.tfvars
echo "project_name=\"$PROJECT\"" >> ../terraform/terraform.tfvars

# update the repo actions secrets with the values
gh secret set AZURE_CLIENT_ID -b "$AZURE_CLIENT_ID"
gh secret set AZURE_CLIENT_SECRET -b "$AZURE_CLIENT_SECRET"
gh secret set AZURE_TENANT_ID -b "$AZURE_TENANT_ID"
gh secret set AZURE_SUBSCRIPTION_ID -b "$AZURE_SUBSCRIPTION_ID"
gh secret set AZURE_OBJECT_ID -b "$SP_OBJECT_ID"

gh secret set AZURE_CREDENTIALS -b "$(jq -n \
  --arg clientId "$AZURE_CLIENT_ID" \
  --arg clientSecret "$AZURE_CLIENT_SECRET" \
  --arg subscriptionId "$AZURE_SUBSCRIPTION_ID" \
  --arg tenantId "$AZURE_TENANT_ID" \
'{"clientId": "$clientId", "clientSecret": "$clientSecret", "subscriptionId": "$subscriptionId", "tenantId": "$tenantId"}')"

gh secret set PAT_TOKEN -b "$GITHUB_TOKEN"

# update the repo variables with the values
gh variable set AZURE_LOCATION -b "$LOCATION"
gh variable set AZURE_GROUP_NAME -b "$RESOURCE_GROUP"
gh variable set PROJECT_NAME -b "$PROJECT"

# print that the secrets and variables are updated with green color
echo -e "\e[32m\xE2\x9C\x94 GitHub secrets and variables updated successfully\e[0m"

# create the terraform storage account which will be used to store the terraform state
# create the name of the storage account by appending a random number to the project name
STORAGE_ACCOUNT_NAME=$PROJECT$RANDOM
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --allow-blob-public-access false > /dev/null 2>&1
if [ $? -eq 0 ]; then
    # with green color checked mark and the message
    echo -e "\e[32m\xE2\x9C\x94 Storage account created successfully\e[0m"
else
    # with red color x mark and the message
    echo -e "\e[31m\xE2\x9C\x98 Storage account creation failed\e[0m"
    # finish the script
    echo "Exiting..."
    exit 0
fi

# create the container in the storage account which will be used to store the terraform state
az storage container create \
  --name tfstate \
  --account-name $STORAGE_ACCOUNT_NAME > /dev/null 2>&1
if [ $? -eq 0 ]; then
    # with green color checked mark and the message
    echo -e "\e[32m\xE2\x9C\x94 Storage container created successfully\e[0m"
else
    # with red color x mark and the message
    echo -e "\e[31m\xE2\x9C\x98 Storage container creation failed\e[0m"
    # finish the script
    echo "Exiting..."
    exit 0
fi

# save the storage account name and the container name in the terrform backend tf file
echo resource_group_name  = \"$RESOURCE_GROUP\" > ../terraform/backend.tfvars
echo storage_account_name = \"$STORAGE_ACCOUNT_NAME\" >> ../terraform/backend.tfvars
echo container_name       = \"tfstate\" >> ../terraform/backend.tfvars

# save it in the github variables
gh variable set TERRAFORM_STORAGE_ACCOUNT_NAME -b $STORAGE_ACCOUNT_NAME
gh variable set TERRAFORM_CONTAINER_NAME -b "tfstate"











