#!/bin/bash

CERTIFICATE_FILE="./keystore.pfx"
# print the file
echo $CERTIFICATE_FILE

# use openssl to view the certificate
# openssl pkcs12 -in $CERTIFICATE_FILE -info -noout

# add the pfx certificate to the azure key vault
az keyvault certificate import \
    --vault-name kv-testdns2 \
    --name mycertificate \
    --file $CERTIFICATE_FILE \
    --password "test1234"

# list the certificates in the key vault
az keyvault certificate list \
    --vault-name kv-testdns2

# show the certificate in the key vault
az keyvault certificate show \
    --vault-name kv-testdns2 \
    --name mycertificate

# load the certificate from the key vault in a app service
az webapp config ssl import \
    --name testdns2 \
    --resource-group gr-testdns2 \
    --key-vault kv-testdns2 \
    --key-vault-certificate-name mycertificate \
    --certificate-name mycertificate



# load the certificate from the key vault in a app service
az webapp config ssl import \
    --name testdns2 \
    --resource-group gr-testdns2 \
    --key-vault kv-testdns2 \
    --key-vault-certificate-name mycertificate3 \
    --certificate-name mycertificate3

az webapp identity show --name testdns2 --resource-group  gr-testdns2

az role assignment create --role "Key Vault Certificate User" \
  --assignee  c1c09848-4228-4f93-a8a3-5a5b762d1492\
  --scope /subscriptions/44feaee5-c984-4c09-a02f-46c7d78ad294/resourceGroups/gr-testdns2/providers/Microsoft.KeyVault/vaults/kv-testdns2

az role assignment create --role "Key Vault Certificate User" \
  --assignee abfa0a7c-a6b6-4736-8310-5855508787cd \
  --scope /subscriptions/44feaee5-c984-4c09-a02f-46c7d78ad294/resourceGroups/gr-testdns2/providers/Microsoft.KeyVault/vaults/kv-testdns2

az role assignment create --role "Key Vault Certificate User" \
  --assignee  57f638f8-02ce-432a-bd90-a455d446bd1b\
  --scope /subscriptions/44feaee5-c984-4c09-a02f-46c7d78ad294/resourceGroups/gr-testdns2/providers/Microsoft.KeyVault/vaults/kv-testdns2

az role assignment create --role "Key Vault Secrets Officer" \
  --assignee  57f638f8-02ce-432a-bd90-a455d446bd1b\
  --scope /subscriptions/44feaee5-c984-4c09-a02f-46c7d78ad294/resourceGroups/gr-testdns2/providers/Microsoft.KeyVault/vaults/kv-testdns2





# make a base64 version of the keystore.pfx
openssl base64 -in $CERTIFICATE_FILE -out keystore.base64


# az keyvault secret set --vault-name kv-testdns2 --name mycertificate --value "$(cat mycertificate-base64.txt)"
az keyvault secret set \
    --vault-name kv-testdns2 \
    --name mycertificate3 \
    --value "$(cat keystore.base64)" \
    --tags ContentType=application/x-pkcs12



service_principal=$(az ad sp create-for-rbac --create-cert)
echo $service_principal
ls /home/codespace/tmprtwwo6n6.pem
az keyvault create -g gr-testdns2 -n kv-testdns33
# give rights to the current logged in user to create certificates using role assignment
az role assignment create \
--role "Key Vault Certificates Officer" \
--assignee $(az account show --query user.name -o tsv) \
--scope /subscriptions/44feaee5-c984-4c09-a02f-46c7d78ad294/resourceGroups/gr-testdns2/providers/Microsoft.KeyVault/vaults/kv-testdns33

# az keyvault certificate import --vault-name vaultname -n cert_name -f cert_file
az keyvault certificate import \
    --vault-name kv-testdns33 \
    -n mycertificate33 \
    -f /home/codespace/tmprtwwo6n6.pem

# lsit all secrets in the key vault
az keyvault secret list --vault-name kv-testdns33

openssl pkcs12 -export \
  -out ./cert.pfx \
  -in ./fullchain.pem \
  -inkey ./privkey.pem \
  -passout pass:test1234

  # show the content of the pfx file
    openssl pkcs12 -in ./cert.pfx -info -noout



I have a wildcard certificate generated by the Let's Encrypt certificate authority. I have the following files:
I want to use this certificate with a Azure App Service. 
Like instructued, I created a .pfx password protected file using the following command:
openssl pkcs12 -export -out ./cert.pfx -in ./fullchain.pem -inkey ./privkey.pem -passout pass:test123

If I try to import the certificate using from Azure portal using "Bring Your Own Certificate" option 
with the .pfx file and password, all runs smoothly. And I can see the certificate imported in the list and 
I can also bind it to the custom domain.

Now, if I try the same file cert.pfx to import it in a Azure Key Vault Certificate, the import works ok but 
when I try to import the certificate in the App Service, I got an permission error.
I followed the instructions from the Microsoft documentation and I gave the App Service Managed Identity the
"Key Vault Certificate User" role and also the "Key Vault Secrets User" role. 
I stop getting the permission error but the certificate is not imported in the App Service and now I get the following error:

An error has occurred.

Thats it, no more details. 

I check out the Key Vault and I see the associated secret with the certificate was created, even if not shown 
in the list of secrets. I was able to access it by name. It was a base64 encoded version of the .pfx file, i suppose.

The question is what do from here? How can I debug this issue? What can be the problem?

Why I need it in the Key Vault? Because I want to automate the process of importing the certificate in the App Service,
using Terraform. And I need to store the certificate in the Key Vault for later GitHub Actions workflow for certificate renewals.
