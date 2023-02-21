# CyberArk Inventory Scripts <!-- omit in toc -->
Scripts to help with inventory of CyberArk products.

- [Getting Started](#getting-started)
- [Secrets Managers](#secrets-managers)
  - [PowerShell](#powershell)
    - [CredentialProviders.ps1](#credentialprovidersps1)
- [License](#license)


## Getting Started

- These scripts are designed to be run on a Windows machine with PowerShell 5.1 or higher.
- They are designed to be run on a machine that has access to the CyberArk REST API.
- The scripts are designed to be run from the command line, but can be run from PowerShell as well.
- The scripts are designed to be run from the directory that they are located in.
- Some scripts will ask for CyberArk Administrator credentials. These credentials are only used to authenticate to the CyberArk REST API and are not stored anywhere.

## Secrets Managers

### PowerShell

#### CredentialProviders.ps1

Uses the CyberArk REST API to retrieve a list of all the Credential Providers registered to the Vault and outputs them to a CSV file called `CredentialProvidersInventory.csv`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.