$port = 8787
$connection = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1

if ($null -eq $connection) {
  Write-Output "No process is listening on port $port."
  exit 0
}

$targetPid = $connection.OwningProcess
$process = Get-Process -Id $targetPid -ErrorAction SilentlyContinue

Write-Output "Stopping process on port $port..."
Write-Output "PID: $targetPid"
Write-Output "Name: $($process.ProcessName)"

Stop-Process -Id $targetPid -Force

Write-Output "Stopped successfully."
