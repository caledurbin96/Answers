# QuickStart.ps1
# Runs key.ps1 to set the API key, then runs Answer3.ps1 with default series.

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = "Stop"

# Ensure we run from this script's folder.
Set-Location -Path (Split-Path -Parent $MyInvocation.MyCommand.Path)

# Load API key for this session.
Write-Output "Setting API key..."
. .\key.ps1
if (-not $env:FRED_API_KEY) {
    Write-Error "FRED_API_KEY is not set. Edit key.ps1 with your API key."
    exit 13
}

# Dedupes list, avoids extra calls.
$seriesList = @("UNRATE","CPIAUCSL","DGS10") | Select-Object -Unique

foreach ($s in $seriesList) {
    Write-Output "Fetching series: $s"
    .\Answer3.ps1 -SeriesId $s -Start 2015-01-01 -MaxAgeHours 6
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        Write-Error "Answer3.ps1 failed for $s (exit=$code)."
        exit $code
    }
    Start-Sleep -Milliseconds 500  # tiny pause to be courteous
}

Write-Output "All done. JSON files saved in the 'output' folder."
exit 0
