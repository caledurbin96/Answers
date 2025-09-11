# QuickStart.ps1
# Simple wrapper to run Answer1.ps1 with FakeProfile.xml in the same folder.

$here      = Split-Path -Parent $MyInvocation.MyCommand.Path
$addScript = Join-Path $here 'Answer1.ps1'
$xmlPath   = Join-Path $here 'FakeProfile.xml'

& $addScript -Path $xmlPath
