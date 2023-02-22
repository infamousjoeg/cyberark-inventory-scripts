$installDir = "unknown"

function Find-SavePath {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $browse = New-Object System.Windows.Forms.FolderBrowserDialog
    $browse.SelectedPath = "C:\"
    $browse.ShowNewFolderButton = $true
    $browse.Description = "Select a directory where the report will be placed"

    do {
        $result = $browse.ShowDialog()

        if ($result -eq "OK") {
            return $browse.SelectedPath
        } else {
            $res = [System.Windows.Forms.MessageBox]::Show("You clicked Cancel. Would you like to try again or exit?", "Select a location", [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
            if ($res -eq "Cancel") {
                # Ends script
                exit 0
            }
        }
    } while ($true)
}

function Find-LogPath($installDir) {
    Add-Type -AssemblyName System.Windows.Forms
    $OpenFolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $OpenFolderDialog.SelectedPath = "C:\"
    $OpenFolderDialog.ShowDialog() | Out-Null
    $folder = $OpenFolderDialog.SelectedPath
    return $folder
}

$savePath = Join-Path (Find-SavePath) "${env:COMPUTERNAME}_CCPInventory.csv"

Read-Host "Please hit Enter to choose the location of your AppAudit.log files"
$installDir = Find-LogPath $installDir

Write-Host "The report will be saved to: $savePath"

# Parse the log file
$addressPattern = '(?<=IP address \[).+?(?=\])'

$FilePath = Get-ChildItem -Path $installDir -Recurse -Filter AppAudit.log.* | Select-Object -ExpandProperty FullName
$uniqueAddresses = Get-ChildItem -Path $FilePath | ForEach-Object {
    Write-Host "The log will be pulled from: $_"
    Get-Content -Path $_ | Where-Object {$_ -Match '.*APPAU005I.*'} | Select-String $addressPattern -AllMatches | Foreach-Object {
        $_.Matches.Value
    }
} | Select-Object -Unique

# Output
Write-Host "`nUnique addresses found:`n"
$uniqueAddresses
Write-Host "`nTotal count of unique addresses: $($uniqueAddresses.Count)"

if (Test-Path $savePath) {
    Remove-Item $savePath
}

$uniqueAddresses | ForEach-Object {
    Add-Content $savePath ($_ -join "")
}

Read-Host -Prompt "`nPress Enter to exit"