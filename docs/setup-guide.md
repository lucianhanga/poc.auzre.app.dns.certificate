# Set up of codespace

## install azure cli

`https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt`


## install terraform

since there might be updates on how terraform should be installed in linux distributions, it is recommended to check the official terraform documentation for the most recent installation instructions.

`https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli`

## login to azure cli

If you loging from a codespace you can use the following command to login to azure cli because the codespace does not have a browser to login.

```bash
az login --use-device-code
```

