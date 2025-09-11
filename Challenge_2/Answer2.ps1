<#
Example:
<ScriptPath>.ps1 -Path <BlockListPath>.txt
C:\Scripts\Answer2.ps1 -Path 'C:\Lists\blocklist.txt'

Codes:
0  = Success
1  = File not found
99 = Unknown error
#>




using namespace System.Text.RegularExpressions

# Script parameters.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [int]$RegexMaxChars = 3000   # used for the bonus regex chunking
)

$ErrorActionPreference = 'Stop'

# Ensure the input file exists.
if (-not (Test-Path -Path $Path -PathType Leaf)) {
    Write-Error "File not found: $Path"
    exit 1
}

# Create an output folder next to the input file.
$root = Split-Path -Path $Path -Parent; if (-not $root) { $root = "." }
$outputDir = Join-Path $root "output"
if (-not (Test-Path $outputDir)) { [void](New-Item -ItemType Directory -Path $outputDir) }

# Quick regexes for pattern matching.
$reIPv4          = '^(?:\d{1,3}\.){3}\d{1,3}$'
$reEmail         = '^[^@\s]+@[^@\s]+\.[^@\s]+$'
$reEmailWildcard = '^\*\@(?:\*\.)?[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$'  # These look like emails but should go in domains
$reStarTld       = '^\*\.[a-z0-9-]{2,}$'
# Exclude '@' from domain-like so malformed emails don't fall through as domains
$reDomainLike    = '^[\*\.A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$'

function Test-IPv4 {
    param([string]$s)
    if ($s -notmatch $reIPv4) { return $false }
    foreach ($o in $s.Split('.')) {
        if (-not ($o -match '^\d+$') -or [int]$o -gt 255) { return $false }
    }
    $true
}

function Test-IPv6 {
    param([string]$s)
    $refIp = [ref]([System.Net.IPAddress]::None)
    [System.Net.IPAddress]::TryParse($s, $refIp) -and $s.Contains(':')
}

function Classify-TldWildcard {
    param([string]$starTld)
    if ($starTld.Length -lt 3) { return 'g' }       # guard malformed like "*."
    if ($starTld.Substring(2).Length -eq 2) { 'cc' } else { 'g' }
}

function New-ChunkedRegex {
    param([string[]]$Items,[string]$Prefix,[string]$Suffix,[int]$MaxChars = 3000)
    $lines=@(); $current=$Prefix; $sep=''
    foreach ($i in $Items) {
        $cand = $current + $sep + [Regex]::Escape($i) + $Suffix
        if ($cand.Length -le $MaxChars) {
            $current += $sep + [Regex]::Escape($i); $sep='|'
        } else {
            if ($current -eq $Prefix) { $lines += ($Prefix + [Regex]::Escape($i) + $Suffix) }
            else { $lines += ($current + $Suffix); $current = $Prefix + [Regex]::Escape($i); $sep='|' }
        }
    }
    if ($current -ne $Prefix) { $lines += ($current + $Suffix) }
    $lines
}

function Get-Apex {
    param([string]$s)
    $d=$s -replace '^\*\@\*\.', '' -replace '^\*\@', '' -replace '^\*\.', ''
    if ($d -match $reEmail) { $d = $d.Split('@')[-1] }
    $parts = $d.Split('.') | Where-Object { $_ }
    if ($parts.Count -ge 2) { "$($parts[-2]).$($parts[-1])" } else { $d }
}

# Buckets.
$ccTLD   = New-Object System.Collections.Generic.HashSet[string]
$gTLD    = New-Object System.Collections.Generic.HashSet[string]
$domains = New-Object System.Collections.Generic.HashSet[string]
$emails  = New-Object System.Collections.Generic.HashSet[string]
$ipv4    = New-Object System.Collections.Generic.HashSet[string]
$ipv6    = New-Object System.Collections.Generic.HashSet[string]

# Main loop.
try {
    Get-Content -Path $Path -ErrorAction Stop | ForEach-Object {
        $line = $_
        if ($null -eq $line) { return }
        $line = $line.Trim().ToLowerInvariant()

        # Strip inline comments (# ... or ; ...) and collapse to first whitespace-delimited token
        $line = ($line -replace '\s*[#;].*$','')
        $line = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { return }
        $line = $line.Split(@(' ', "`t"))[0]
        if ([string]::IsNullOrWhiteSpace($line)) { return }

        # Skip full-line comments (defensive—already stripped)
        if ($line.StartsWith('#', [StringComparison]::Ordinal) -or $line.StartsWith(';', [StringComparison]::Ordinal)) { return }

        if (Test-IPv4 $line) { [void]$ipv4.Add($line); return }
        if (Test-IPv6 $line) { [void]$ipv6.Add($line); return }

        if ($line -match $reEmail -and $line -notmatch $reEmailWildcard) { [void]$emails.Add($line); return }

        if ($line -match $reStarTld) {
            switch (Classify-TldWildcard $line) { 'cc' { [void]$ccTLD.Add($line) } 'g' { [void]$gTLD.Add($line) } }
            return
        }

        if ($line -match $reDomainLike -or ($line.Contains('.') -and -not $line.Contains('@'))) {
            [void]$domains.Add($line); return
        }
    }
}
catch {
    Write-Error "Error parsing file: $($_.Exception.Message)"
    exit 99
}

# Save helper (I/O guarded)
function Save-List {
    param(
        [System.Collections.Generic.HashSet[string]]$Set,
        [string]$Name
    )
    $p = Join-Path $outputDir $Name
    try {
        $Set | Sort-Object | Set-Content -Path $p -Encoding UTF8 -ErrorAction Stop
        Write-Host ".\output\$Name has been created with $($Set.Count) items"
    }
    catch {
        Write-Error "Failed to write ${Name}: $($_.Exception.Message)"
        exit 99
    }
}  # <-- brace present

# Generate the six files.
Save-List $ccTLD   "ccTLD-blocklist.txt"
Save-List $gTLD    "TLD-blocklist.txt"
Save-List $domains "domain-subdomain-blocklist.txt"
Save-List $emails  "email-blocklist.txt"
Save-List $ipv4    "ipv4-blocklist.txt"
Save-List $ipv6    "ipv6-blocklist.txt"

# EXO regex files.
try {
    $tldItems = @()
    foreach ($x in $gTLD) { $tldItems += $x.Substring(2) }
    foreach ($x in $ccTLD) { $tldItems += $x.Substring(2) }
    $tldItems = $tldItems | Sort-Object -Unique
    $tldRegex = if ($tldItems) { New-ChunkedRegex -Items $tldItems -Prefix '\.(' -Suffix ')$' -MaxChars $RegexMaxChars } else { @() }
    $tldPath  = Join-Path $outputDir "EXO-TLD-Regex.txt"

    try {
        $tldRegex | Set-Content -Path $tldPath -Encoding UTF8 -ErrorAction Stop
        if ($tldRegex.Count) { Write-Host ".\output\EXO-TLD-Regex.txt has been created with $($tldRegex.Count) items" }
    }
    catch {
        Write-Error "Could not write EXO-TLD-Regex.txt: $($_.Exception.Message)"
        exit 99
    }

    $apexMap = @{}
    foreach ($d in $domains) {
        $apex = Get-Apex $d
        if (-not $apexMap.ContainsKey($apex)) { $apexMap[$apex] = $true }
    }
    $apexes  = $apexMap.Keys | Sort-Object -Unique
    $domRegex = if ($apexes) { New-ChunkedRegex -Items $apexes -Prefix '\.(' -Suffix ')$' -MaxChars $RegexMaxChars } else { @() }
    $domPath = Join-Path $outputDir "EXO-DomainRegex.txt"

    try {
        $domRegex | Set-Content -Path $domPath -Encoding UTF8 -ErrorAction Stop
        if ($domRegex.Count) { Write-Host ".\output\EXO-DomainRegex.txt has been created with $($domRegex.Count) items" }
    }
    catch {
        Write-Error "Could not write EXO-DomainRegex.txt: $($_.Exception.Message)"
        exit 99
    }
}
catch {
    Write-Warning "Could not build regex: $($_.Exception.Message)"
}

# Final summary.
Write-Host ("Totals => ccTLD:{0} TLD:{1} domains:{2} emails:{3} IPv4:{4} IPv6:{5}" -f `
    $ccTLD.Count, $gTLD.Count, $domains.Count, $emails.Count, $ipv4.Count, $ipv6.Count)

exit 0

