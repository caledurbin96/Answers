<#
QuickStart.ps1
Runs Answer2.ps1 against the local blocklist.txt file and writes results to ./output
#>

# Resolve paths relative to this script’s directory
$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath  = Join-Path $scriptDir "Answer2.ps1"
$blocklist   = Join-Path $scriptDir "blocklist.txt"

# Check that files exist
if (-not (Test-Path $scriptPath -PathType Leaf)) {
    Write-Error "Answer2.ps1 not found in $scriptDir"
    exit 1
}
if (-not (Test-Path $blocklist -PathType Leaf)) {
    Write-Error "blocklist.txt not found in $scriptDir"
    exit 1
}

# Run the main script with the blocklist
& $scriptPath -Path $blocklist
