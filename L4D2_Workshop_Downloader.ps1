# Should be saved as a .ps1 file to register as PowerShell.
# Execute: Right click this file, choose "Run with PowerShell".
# Execute: In powershell, enter directory where this is located then ./L4D2_Workshop_Downloader.ps1

# Optional: Can be ran with an argument pointing to a text file
# .\L4D2_Workshop_Downloader.ps1 -FilePath "C:\My\Path\To\WorkShopItems.txt"
# Suports full http urls or just the workshop id.
param (
    [string]$FilePath = ""
)
 
# Variables
[Int]$itemIndex = 0
$enteredWorkshopItems = New-Object System.Collections.ArrayList

# Get the path this script is located in
$path = $PSScriptRoot

# Check if file path is provided
if ([string]::IsNullOrWhiteSpace($FilePath) -eq $false -and (Test-Path -Path $FilePath)) {
    # Read lines from the file and add to the list
    Get-Content -Path $FilePath | ForEach-Object {
        [void]$enteredWorkshopItems.Add($_)
    }
} else {
	Write-Host @"

-- Workshop Downloader for Left 4 Dead --

Enter the workshop ID or the url. Press Enter to add another item. 

Pressing Enter with nothing entered will start the download process.

Files will be downloaded alongside this script file. 

-----------------------------------------
"@ -ForegroundColor yellow
	
	# Input workshop items by id or url, continue on empty input
    while ($true) {
        $input = Read-Host "Input $((++$itemIndex))"
        
        if ($input -ne '') {
            [void]$enteredWorkshopItems.Add($input)
        } else {
            Write-Host "Finished entering workshop items"
            break
        }
    }
}

# Sanitize workshop urls for their id query
for($index = 0; $index -lt $enteredWorkshopItems.Count; $index++)
{
	$item = $enteredWorkshopItems[$index]
    if($item -match '(http[s]?|[s]?ftp[s]?)(:\/\/)([^\s,]+)') {	
		[uri]$url = $item
		$token = ($url.Query -split '=')[1]
		$enteredWorkshopItems[$index] = $token
	}
}

# Steam API Url
# See: https://steamapi.xpaw.me/#ISteamRemoteStorage/GetPublishedFileDetails
$steamApiUrl = "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1"

# Body
$body = [ordered]@{}
$body.Add("itemcount", $enteredWorkshopItems.Count)
for($index = 0; $index -lt $enteredWorkshopItems.Count; $index++) {
	$body.Add(-join("publishedfileids[", $index, "]"), $enteredWorkshopItems[$index])
}

# Invoke and get it's response
$response = Invoke-RestMethod -Uri $steamApiUrl -Method POST -Body $body
$jsonResponse = $response | ConvertTo-Json -Depth 10 | ConvertFrom-Json

# Download the workshop items alongside where the script is located.
foreach ($fileUrl in $jsonResponse.response.publishedfiledetails) {
	$file = $fileUrl | Select-Object -ExpandProperty file_url	
	$filename = $fileUrl | Select-Object -ExpandProperty filename	
	$title = $fileUrl | Select-Object -ExpandProperty title	
	
	
	# There is a chance the 'filename' will have directories with the actual name 
	# Strip those directories
	if ($filename -match "/") { 
		$filename = $filename.Substring($filename.lastIndexOf('/') + 1)
	}
	
	# TODO: Rename files automatically
	
	Write-Host "Downloading: $title"
	$ProgressPreference = "SilentlyContinue"
	
	$filePath = Join-Path -Path $path -ChildPath $filename
	Invoke-WebRequest -Uri $file -OutFile $filePath
}

Write-Host "Finished!" -ForegroundColor green