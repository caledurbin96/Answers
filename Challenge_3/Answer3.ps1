<#
Example:
<KeyPath>.ps1
C:\Answers\Challenge_3\key.ps1

<ScriptPath>.ps1 -SeriesId <FREDSeriesID> -Start <StartDate>
C:\Answers\Challenge_3\Answer3.ps1 -SeriesId UNRATE -Start 2015-01-01
C:\Answers\Challenge_3\Answer3.ps1 -SeriesId CPIAUCSL -Start 2015-01-01
C:\Answers\Challenge_3\Answer3.ps1 -SeriesId DGS10 -Start 2015-01-01

Codes:
0  = Success
2  = No observations / no usable values
10 = Network unavailable (DNS/connection/timeout)
11 = API unavailable (5xx after retries)
12 = Rate limited (429 after retries)
13 = Bad request / invalid series (4xx) or missing key
99 = Unknown error
#>

#Script Parameters.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SeriesId,

    [ValidateNotNullOrEmpty()]
    [string]$Start = "2015-01-01",

    # Output directory for JSON files
    [ValidateNotNullOrEmpty()]
    [string]$OutDir = "output",

    # Skip API call if an existing JSON is newer than this many hours (avoids overuse)
    [int]$MaxAgeHours = 6,

    # Force refresh even if cache is fresh
    [switch]$Force,

    # Log file path
    [ValidateNotNullOrEmpty()]
    [string]$LogPath = "logs\challenge3.log"
)

$ErrorActionPreference = "Stop"
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# Ensure modern TLS on Windows PowerShell 5.1.
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }
}

function Write-Log {
    param([string]$Message)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[${ts}] [Answer3] $Message"
    $dir = Split-Path -Parent $LogPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    Add-Content -Path $LogPath -Value $line -ErrorAction Stop
}

try {
    # Validate/normalize inputs.
    $apiKey = ($env:FRED_API_KEY).Trim()
    if (-not $apiKey) {
        Write-Error "FRED_API_KEY not set. Run .\key.ps1 first."
        exit 13
    }

    $SeriesId = $SeriesId.Trim().ToUpperInvariant()
    if ($SeriesId -notmatch '^[A-Z0-9._-]+$') {
        Write-Error "Invalid SeriesId. Allowed: letters, digits, dot, underscore, hyphen."
        exit 13
    }

    # Validate Start, the date format and not in the future.
    try {
        $null = [datetime]::ParseExact($Start, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
    } catch {
        Write-Error "Start must be in format YYYY-MM-DD (e.g., 2015-01-01)."
        exit 13
    }
    $startDt = [datetime]::ParseExact($Start, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
    $today   = (Get-Date).Date
    if ($startDt -gt $today) {
        Write-Error "Start date cannot be in the future."
        exit 13
    }

    if ($MaxAgeHours -lt 0) {
        Write-Error "MaxAgeHours cannot be negative."
        exit 13
    }

    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
    $jsonPath = Join-Path $OutDir "$SeriesId.json"

    # Cache check.
    if (-not $Force -and (Test-Path $jsonPath)) {
        $ageHrs = ((Get-Date) - (Get-Item $jsonPath).LastWriteTime).TotalHours
        if ($ageHrs -lt $MaxAgeHours) {
            Write-Output "Using cached JSON for $SeriesId (age: $([math]::Round($ageHrs,2))h): $jsonPath"
            Write-Log "CACHE_USED series=$SeriesId ageHours=$([math]::Round($ageHrs,2)) path=$jsonPath"
            exit 0
        }
    }

    # GET with retries/backoff/jitter and URL validation/logging.
    function Invoke-WithRetry {
        param(
            [Parameter(Mandatory=$true)][string]$BaseUrl,
            [Parameter(Mandatory=$true)][hashtable]$Params
        )

        # Normalize & validate URL.
        $BaseUrl = $BaseUrl.Trim()
        if (-not [Uri]::IsWellFormedUriString($BaseUrl, [UriKind]::Absolute)) {
            Write-Log "BAD_BASEURL '$BaseUrl'"
            throw "ClientError:400"
        }

        # Build query string.
        $kv = foreach ($k in $Params.Keys) {
            $val = $Params[$k]
            if ($null -ne $val) {
                $ek = [Uri]::EscapeDataString([string]$k)
                $ev = [Uri]::EscapeDataString(([string]$val).Trim())
                "{0}={1}" -f $ek, $ev
            }
        }
        $qs = ($kv -join '&')
        $fullUrl = if ($qs) { "$BaseUrl`?$qs" } else { $BaseUrl }

        # Check & log.
        if (-not [Uri]::IsWellFormedUriString($fullUrl, [UriKind]::Absolute)) {
            Write-Log "BAD_URL '$fullUrl'"
            throw "ClientError:400"
        }
        Write-Log "REQUEST $fullUrl"

        $headers = @{
            "User-Agent" = "Answer3.ps1 (PowerShell)"
            "Accept"     = "application/json"
        }

        $maxAttempts = 5
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            try {
                # PS5.1-safe; ignored by PS7+
                return Invoke-WebRequest -UseBasicParsing -Uri $fullUrl -Headers $headers -Method Get -TimeoutSec 30
            } catch {
                $statusCode = $null
                $retryAfter = $null
                if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
                    $statusCode = [int]$_.Exception.Response.StatusCode
                    try { $retryAfter = $_.Exception.Response.Headers["Retry-After"] } catch {}
                }

                if ($statusCode -eq 429) {
                    $sleep = if ($retryAfter) { [int]$retryAfter } else { [math]::Pow(2, $attempt) }
                    Write-Log "RETRY 429 series=$SeriesId attempt=$attempt sleep=${sleep}s"
                    Start-Sleep -Seconds $sleep
                }
                elseif ($statusCode -ge 500 -and $statusCode -lt 600) {
                    $sleep = [math]::Pow(2, $attempt) + (Get-Random -Minimum 0 -Maximum 500)/1000.0
                    Write-Log "RETRY 5xx=$statusCode series=$SeriesId attempt=$attempt sleep=${sleep}s"
                    Start-Sleep -Seconds $sleep
                }
                elseif ($statusCode -ge 400 -and $statusCode -lt 500) {
                    Write-Log "FAIL 4xx=$statusCode series=$SeriesId msg=$($_.Exception.Message)"
                    throw [System.Exception]::new("ClientError:$statusCode")
                }
                else {
                    $sleep = [math]::Pow(2, $attempt) + (Get-Random -Minimum 0 -Maximum 500)/1000.0
                    Write-Log "RETRY NETWORK series=$SeriesId attempt=$attempt sleep=${sleep}s err=$($_.Exception.Message)"
                    Start-Sleep -Seconds $sleep
                }

                if ($attempt -eq $maxAttempts) { throw }
            }
        }
    }

    # Get JSON content from FRED.
    $url = 'https://api.stlouisfed.org/fred/series/observations'
    $params = @{
        api_key           = $apiKey
        file_type         = 'json'
        series_id         = $SeriesId
        observation_start = $Start
    }

    $resp = Invoke-WithRetry -BaseUrl $url -Params $params

    # JSON string.
    $raw = $resp.Content
    if (-not $raw -or $raw.Trim().Length -eq 0) {
        Write-Error "Empty response for $SeriesId."
        Write-Log   "NO_DATA_EMPTY series=$SeriesId"
        exit 2
    }

    # Quick structural + usability check.
    $obj = $null
    try { $obj = $raw | ConvertFrom-Json } catch {
        Write-Error "Response was not valid JSON."
        Write-Log   "INVALID_JSON series=$SeriesId"
        exit 99
    }

    if (-not $obj.observations -or $obj.observations.Count -eq 0) {
        Write-Error "No observations returned for $SeriesId."
        Write-Log   "NO_DATA series=$SeriesId"
        exit 2
    }

    # Require at least one numeric value.
    $usable = $obj.observations | Where-Object { $_.value -match '^-?\d+(\.\d+)?$' }
    if (-not $usable -or $usable.Count -eq 0) {
        Write-Error "No usable numeric observations for $SeriesId."
        Write-Log   "NO_USABLE_DATA series=$SeriesId"
        exit 2
    }

    # ---- Save raw JSON exactly as returned ----
    Set-Content -LiteralPath $jsonPath -Value $raw -Encoding UTF8 -ErrorAction Stop

    $sw.Stop()
    Write-Output "Saved JSON: $jsonPath"
    Write-Log "SUCCESS series=$SeriesId ms=$($sw.ElapsedMilliseconds) json=$jsonPath"
    exit 0
}
catch {
    $sw.Stop()
    $msg = $_.Exception.Message
    if ($_.Exception.Message -like "ClientError:*") {
        Write-Error "Bad request or invalid series: $SeriesId"
        Write-Log   "FAIL_4XX series=$SeriesId msg=$msg ms=$($sw.ElapsedMilliseconds)"
        exit 13
    }
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
        $code = [int]$_.Exception.Response.StatusCode
        if ($code -eq 429) { Write-Log "FAIL_429 series=$SeriesId ms=$($sw.ElapsedMilliseconds)"; exit 12 }
        if ($code -ge 500 -and $code -lt 600) { Write-Log "FAIL_5XX=$code series=$SeriesId ms=$($sw.ElapsedMilliseconds)"; exit 11 }
    }
    if ($_.Exception -is [System.Net.WebException]) {
        Write-Log "FAIL_NET series=$SeriesId err=$msg ms=$($sw.ElapsedMilliseconds)"
        Write-Error "Network unavailable or timed out."
        exit 10
    }
    Write-Log "FAIL_UNKNOWN series=$SeriesId err=$msg ms=$($sw.ElapsedMilliseconds)"
    Write-Error "Unexpected error: $msg"
    exit 99
}

