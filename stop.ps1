# stop.ps1


##################################################################
# Kill previous instances that may still be running
##################################################################

# Kill all other PowerShell processes (except the current one running this start script)
Get-Process powershell | Where-Object { $_.Id -ne $PID } | Stop-Process -Force

# Kill old instances if they are running
Write-Host "Killing any running instances of Prometheus, Loki, Tempo, and OTEL Collector..."
Stop-Process -Name "prometheus", "loki-windows-amd64", "tempo", "otelcol" -ErrorAction SilentlyContinue -Force

Write-Host "LGTM Stack has been successfully shut down."