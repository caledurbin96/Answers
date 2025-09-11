<#
Example:
<ScriptPath>.ps1 -Path '<ProfilePath>.xml'
C:\Scripts\Add-WLANProfile.ps1 -Path 'C:\Profiles\CorpWiFi.xml'

Codes:
0  = Success (added)
1  = File missing
2  = Malformed/invalid XML
10 = Skipped (profile already exists)
99 = Unknown error
#>



# Script Parameters.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

$ErrorActionPreference = 'Stop'

# Ensure the file exists and resolve to a full path.
try {
    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
}
catch {
    Write-Error "The supplied XML profile is missing."
    exit 1
}

# Load XML.
try {
    $raw = Get-Content -LiteralPath $resolved -Encoding UTF8 -Raw
    [xml]$doc = $raw
}
catch {
    Write-Error "The supplied XML profile is malformed."
    exit 2
}

# Extract & validate profile name.
$nameNode = $doc.SelectSingleNode('/*[local-name()="WLANProfile"]/*[local-name()="name"]')
$name = ""
if ($null -ne $nameNode) { $name = ($nameNode.InnerText).Trim() }
if (-not $name) {
    Write-Error "The XML profile is malformed."
    exit 2
}

# Check if profile already exists.
# Example line: '    All User Profile     : CorpWiFi'
$profiles = netsh wlan show profiles
if ($profiles -match "(?m):\s*$([Regex]::Escape($name))\s*$") {
    Write-Warning "The network '$name' is already added."
    exit 10
}

# Attempt to add the profile (for all users).
$out  = netsh wlan add profile filename="$resolved" user=all
$code = $LASTEXITCODE

# Normalize common outcomes from netsh output.
if ($out -match '(?i)\b(is\s+added|added\s+on\s+interface)\b' -or $code -eq 0) {
    Write-Host "Profile '$name' added successfully!"
    exit 0
}

# If the add call itself reports it already exists.
if ($out -match '(?i)\balready\s+exists\b') {
    Write-Warning "The network '$name' is already added."
    exit 10
}

Write-Error ("An unknown error occurred.`n{0}" -f $out)
exit 99


