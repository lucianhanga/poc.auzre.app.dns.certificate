# Configuring Azure DNS


## Get an Name from a Domain Registrar 

For the purpose of this documentation, I used [ionos.com](https://www.ionos.com) to register a domain name. 
If you don't want your personal information to be public, you can use the domain privacy feature. 

![alt text](images/ionos-domain-privacy.png "Domain Privacy")

⚠️ **Warning:**  If you enable domain privacy, the contract will automatically renew after the first year. You can disable the domain privacy feature after the first year.

## Locate the DNS Settings

After you have registered a domain name, you will need to locate the DNS settings. This is where you will add the Azure DNS servers.

![alt text](images/ionos-dns-settings.png "DNS Settings")



## Azure Console

Login to the Azure console with your developer account. And click on the `Create a resource` button. Search for `DNS Zone` and click on the `Create` button.

![alt text](images/add-azure-dns-zone.png "Azure Console")

### Create a DNS Zone

Create a new resoruce group or use an existing one. Enter the domain name you registered and click on the `Review + Create` button.
Then click on the `Create` button.

![alt text](images/create-dns-zone.png "Create DNS Zone")

Wait a few minutes for the DNS zone to be created.
Once the DNS zone is created, click on the `Go to resource` button.
Here you will see the DNS servers that you will need to add to your domain registrar.

![alt text](images/dns-servers.png "DNS Servers")

### Add DNS Servers to Domain Registrar

Go back to your domain registrar and add the DNS servers to the DNS settings.

![alt text](images/ionos-dns-settings2.png "DNS Settings")

![alt text](images/ionos-dns-servers.png "DNS Servers")

⚠️ **Important:**  Don't forget to remove the **dots** at the end of the DNS servers, because otherwise you will get an error message.

⚠️ **Important:** Once this completed, you will need to wait a few minutes for the DNS servers to propagate. You can check the status of the DNS servers by using the `nslookup` command.

### Verify DNS Servers

Open a terminal and type the following command to see if the DNS servers have been propagated. Replace `your-domain-name.com` with your domain name.

```bash
nslookup -type=NS your-domain-name.com 8.8.8.8
```

if you don't have it installed, you can install it with the following command:

```bash
sudo apt-get install dnsutils
```

Before the DNS servers have propagated, you should see something like this (or a similar output, depending on your domain registrar):

![alt text](images/nslookup.png "nslookup")

After the DNS servers have propagated, you should see something like this:

![alt text](images/nslookup2.png "nslookup2")

## Azure CLI

You can also use the Azure CLI to create a DNS zone. First login with you developer account:

```bash 
az login
```
Create a resource group with the following command:

```bash
az group create --name gr-testdns2 --location westeurope
```

Then create a new DNS zone with the following command:

```bash
az network dns zone create -g gr-testdns2 -n r0w.online
```

you an output similar with:

```json
{
  "etag": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "id": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/gr-testdns2/providers/Microsoft.Network/dnszones/example.com",
  "location": "global",
  "maxNumberOfRecordSets": 10000,
  "name": "example.com",
  "nameServers": [
    "ns1-04.azure-dns.com.",
    "ns2-04.azure-dns.net.",
    "ns3-04.azure-dns.org.",
    "ns4-04.azure-dns.info."
  ],
  "numberOfRecordSets": 2,
  "resourceGroup": "gr-testdns2",
  "tags": {},
  "type": "Microsoft.Network/dnszones",
  "zoneType": "Public"
}
```

You can also use the Azure CLI to get the DNS servers:

```bash
az network dns zone show -g gr-testdns2 -n r0w.online --query nameServers
```

You should see an output similar with:

```json
[
  "ns1-04.azure-dns.com.",
  "ns2-04.azure-dns.net.",
  "ns3-04.azure-dns.org.",
  "ns4-04.azure-dns.info."
]
```
## Terraform

For the terraform code, check out the `./terraform` directory, where is the IaC code for this project.
