param(
  [string]$Device = '127.0.0.1:5555',
  [string]$HdcPath = 'D:\downloading\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
)

$ErrorActionPreference = 'Stop'
$backend = $PSScriptRoot
$node = (Get-Command node -ErrorAction Stop).Source

$existing = Get-CimInstance Win32_Process -Filter "name='node.exe'" |
  Where-Object { $_.CommandLine -like '*harmonyos-error-diagnosis*backend*server.js*' }
if (-not $existing) {
  Start-Process -FilePath $node -ArgumentList 'server.js' -WorkingDirectory $backend -WindowStyle Hidden
  Start-Sleep -Milliseconds 800
}

& $HdcPath -t $Device rport tcp:8787 tcp:8787
$health = Invoke-RestMethod -Uri 'http://127.0.0.1:8787/health' -TimeoutSec 3
Write-Output "API ready: $($health.status), model=$($health.model), device=$Device"
