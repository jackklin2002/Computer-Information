# Get the machine name
$machineName = $env:COMPUTERNAME

# Define the folder path to store all text files on the USB drive
$usbDriveLetter = "E:\"  # Change this to your USB drive's letter
$folderPath = Join-Path -Path $usbDriveLetter -ChildPath "${machineName}_Reports"

# Create the folder if it doesn't exist
if (-not (Test-Path -Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath | Out-Null
}

# Define the output file paths within the folder
$biosOutputFile = Join-Path -Path $folderPath -ChildPath "${machineName}_BIOSInfo.txt"
$localUsersOutputFile = Join-Path -Path $folderPath -ChildPath "${machineName}_LocalUsersInfo.txt"
$osOutputFile = Join-Path -Path $folderPath -ChildPath "${machineName}_OSInfo.txt"
$installedAppsOutputFile = Join-Path -Path $folderPath -ChildPath "${machineName}_InstalledApps.txt"

# BIOS Information Collection
try {
    $biosInfo = Get-CimInstance -ClassName Win32_BIOS

    $biosDetails = @()
    $biosDetails += "BIOS Information for $machineName"
    $biosDetails += "-----------------------------------"
    $biosDetails += "Manufacturer: $($biosInfo.Manufacturer)"
    $biosDetails += "Name: $($biosInfo.Name)"
    $biosDetails += "Version: $($biosInfo.SMBIOSBIOSVersion)"
    $biosDetails += "Release Date: $($biosInfo.ReleaseDate)"
    $biosDetails += "Serial Number: $($biosInfo.SerialNumber)"
    $biosDetails += "BIOS Version: $($biosInfo.Version)"
    $biosDetails += "BIOS Characteristics: $($biosInfo.BIOSCharacteristics -join ', ')"
    $biosDetails += "BIOS Installable: $($biosInfo.Installable)"
    $biosDetails += "SMBIOS Version: $($biosInfo.SMBIOSVersion)"
    $biosDetails += "Current Language: $($biosInfo.CurrentLanguage)"
    $biosDetails += "System Name: $($biosInfo.SystemName)"
    $biosDetails += "Bootup State: $($biosInfo.BootupState)"
    $biosDetails += "Last Boot Up Time: $($biosInfo.LastBootUpTime)"

    $biosDetails | Out-File -FilePath $biosOutputFile -Encoding UTF8
    Write-Host "BIOS information saved to $biosOutputFile"
} catch {
    Write-Host "An error occurred while retrieving BIOS information: $_"
}

# Local Users Information Collection
$localUsers = Get-WmiObject Win32_UserAccount | Where-Object { $_.LocalAccount -eq $true }

$localUsersContent = "Local User Accounts Information on $machineName`n"
$localUsersContent += "==============================`n`n"

foreach ($user in $localUsers) {
    $localUsersContent += "Name: $($user.Name)`n"
    $localUsersContent += "SID: $($user.SID)`n"
    $localUsersContent += "Full Name: $($user.FullName)`n"
    $localUsersContent += "Disabled: $($user.Disabled)`n"
    $localUsersContent += "Last Logon: $($user.LastLogon)`n"
    $localUsersContent += "Password Expires: $($user.PasswordExpires)`n"
    $localUsersContent += "==============================`n`n"
}

$localUsersContent | Out-File -FilePath $localUsersOutputFile -Encoding UTF8
Write-Host "Local users information saved to $localUsersOutputFile"

# OS Information and Update History Collection
$osVersion = (Get-WmiObject -Class Win32_OperatingSystem).Version
$updateHistory = Get-HotFix | Select-Object InstalledOn, Description, HotFixID
$assetName = $env:COMPUTERNAME

Add-Content -Path $osOutputFile -Value "Asset Name: $assetName"
Add-Content -Path $osOutputFile -Value "OS Version: $osVersion"
Add-Content -Path $osOutputFile -Value "`nOS Update History:`n"

$updateHistory | ForEach-Object {
    $line = "Installed On: $($_.InstalledOn), Description: $($_.Description), HotFixID: $($_.HotFixID)"
    Add-Content -Path $osOutputFile -Value $line
}

Write-Host "OS information and update history saved to $osOutputFile"

# Installed Applications Collection
$applications = Get-WmiObject -Class Win32_Product | Select-Object Name, Version, Vendor

if ($applications) {
    "Installed Applications:" | Out-File -FilePath $installedAppsOutputFile

    foreach ($app in $applications) {
        "$($app.Name) - Version: $($app.Version) - Vendor: $($app.Vendor)`n" | Out-File -FilePath $installedAppsOutputFile -Append
    }
    Write-Host "Application details saved to $installedAppsOutputFile"
} else {
    Write-Host "No applications found."
}
