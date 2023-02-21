# Description: Retrieves a list of Credential Providers from the CyberArk REST API and exports to a CSV file

# Define CyberArk REST API Function
# ---------------------------------
# This function is used to invoke the CyberArk REST API
# It returns the HTTP status code and the response body
# The response body is returned as a PowerShell object
function Invoke-CyberArkRestApi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $AccessToken,
        [Parameter(Mandatory = $true)]
        [ValidateSet("GET", "POST", "PUT", "PATCH", "DELETE")]
        [string]
        $Method,
        [Parameter(Mandatory = $true)]
        [string]
        $URI,
        [Parameter(Mandatory = $false)]
        [string]
        $Body
    )

    $request = @{
        Method = $Method
        URI = $URI
        Headers = @{
            "Content-Type" = "application/json"
            "Authorization" = $AccessToken
        }
        StatusCodeVariable = "StatusCode"
        ErrorAction = "SilentlyContinue"
    }

    if ($Method -in ("POST", "PUT", "PATCH")) {
        $request["Body"] = $Body
    }

    $response = Invoke-RestMethod @request
    return $StatusCode, $response
}

# User-Defined Variables
# ----------------------
# The base URI for the CyberArk REST API (e.g. https://cyberark.example.com)
$baseURI = Read-Host -Prompt "Enter the base URI for the CyberArk REST API (e.g. https://cyberark.example.com)"
if ($baseURI -eq "") {
    Write-Error "Error: No base URI specified"
    Exit 1
}

# The authentication type to use (cyberark or ldap)
$authType = Read-Host -Prompt "Enter the authentication type ([cyberark] or ldap)"
if ($authType -eq "") {
    $authType = "cyberark"
}
$authType = $authType.ToLower()

# Get CyberArk Administrator Credentials
$credentials = Get-Credential -Message "Enter your CyberArk Administrator credentials"
$Body = @{
    "username" = $credentials.GetNetworkCredential().UserName
    "password" = $credentials.GetNetworkCredential().Password
    "concurrentSession" = "true"
}
Remove-Variable -Name credentials

# Define CyberArk REST API Logon Parameters
$logonPostParams = @{
    Headers = @{
        "Content-Type" = "application/json"
    }
    Method = "POST"
    URI = $baseURI + "/passwordvault/api/auth/" + $authType + "/logon"
    ErrorAction = "Stop"
}
$logonPostParams["Body"] = $Body | ConvertTo-Json

# Logon to CyberArk REST API
$AccessToken = Invoke-RestMethod @logonPostParams

# Get System Health Details for AIM Component
$URI = $baseURI + "/passwordvault/api/componentsmonitoringdetails/aim"
$StatusCode, $response = Invoke-CyberArkRestApi -AccessToken $AccessToken -Method "GET" -URI $URI

# If the HTTP status code is 200, export the response to a CSV file
if ($StatusCode -eq 200) {
    if (Test-Path "CredentialProvidersInventory.csv") {
        Remove-Item "CredentialProvidersInventory.csv"
    }
    $response.ComponentsDetails | Export-Csv -Path "CredentialProvidersInventory.csv" -NoClobber -Force
}
else {
    Write-Error "Error: $StatusCode"
}