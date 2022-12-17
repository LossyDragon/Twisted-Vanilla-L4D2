# Should be saved as a .ps1 file to register as PowerShell.
# Execute: Right click this file, choose "Run with PowerShell".
# Execute: In powershell, enter directory where this is located then ./L4D2_Workshop_Downloader.ps1

Write-Host @"

-- Workshop Downloader for Left 4 Dead --

Enter the workshop ID or the url. Press Enter to add another item. 

Pressing Enter with nothing entered will start the download process.

Files will be downloaded alongside this script file. 

-----------------------------------------
"@ -ForegroundColor yellow

# Steam API Url
# See: https://steamapi.xpaw.me/#ISteamRemoteStorage/GetPublishedFileDetails
[String]$steamApiUrl = "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1"
   
# Variables
[Int]$itemIndex = 0
[String[]]$enteredWorkshopItems = @()

# Get the path this script is located in
$path = $PSScriptRoot

# Input workshop items by id or url, continue on empty input
while ($true) {
	$textInput = Read-Host "Input $((++$itemIndex))"
	
	if ($textInput -eq '') {
		Write-Host "Finished entering workshop items" -ForegroundColor yellow
		break
	}
	
	$enteredWorkshopItems += $textInput
}

# Sanitize workshop urls for their id query
# https://steamcommunity.com/sharedfiles/filedetails/?id=1234567890  --> 1234567890
# https://steamcommunity.com/sharedfiles/filedetails/?id=1234567890&searchtext= --> 1234567890
for ($index = 0; $index -lt $enteredWorkshopItems.Length; $index++) {
	$item = $enteredWorkshopItems[$index]
	if ($item -match '(http[s]?)(:\/\/)([^\s,]+)') {	
		[Uri]$url = $item
		[String]$token = ($url.Query -split '=|&')[1]
		$enteredWorkshopItems[$index] = $token
	}
}

# Body
$body = [ordered]@{}
$body.Add("itemcount", $enteredWorkshopItems.Count)
for ($index = 0; $index -lt $enteredWorkshopItems.Length; $index++) {
	$body.Add( -join ("publishedfileids[", $index, "]"), $enteredWorkshopItems[$index])
}

# Show status
Write-Host "Found $($enteredWorkshopItems.Count) ids" -ForegroundColor yellow
Write-Host "$($body | Out-String)" -ForegroundColor yellow

# Invoke and get it's response
$response = Invoke-RestMethod -Uri $steamApiUrl -Method POST -Body $body
$jsonResponse = $response | ConvertTo-Json -Depth 10 | ConvertFrom-Json

# Download the workshop items alongside where the script is located
foreach ($fileUrl in $jsonResponse.response.publishedfiledetails) {
	[String]$file = $fileUrl | Select-Object -ExpandProperty file_url	
	[String]$filename = $fileUrl | Select-Object -ExpandProperty filename	
	[String]$title = $fileUrl | Select-Object -ExpandProperty title	
	
	# Some workshop item filenames will have directories as part of the name, strip it
	if ($filename -match "/") { 
		$filename = $filename.Substring($filename.lastIndexOf('/') + 1)
	}
	
	# TODO: Rename files automatically
	
	# Slow as balls! Usually with Campaigns
	Write-Host "Downloading: $title"
	$ProgressPreference = "SilentlyContinue" # Should speed up download progress
	Invoke-WebRequest -Uri $file -OutFile $path\$filename
}

Write-Host "Finished!" -ForegroundColor green
