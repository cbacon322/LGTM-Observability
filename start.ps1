# start.ps1


##################################################################
# Opens services in organized windows
##################################################################

# Add Windows API function for repositioning windows
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
}
"@

function Set-WindowPosition {
    param(
        [System.Diagnostics.Process]$Process,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height
    )
    # Wait until the process has a main window handle
    while ($Process.MainWindowHandle -eq 0) {
        Start-Sleep -Milliseconds 100
        $Process.Refresh()
    }
    $handle = $Process.MainWindowHandle
    $SWP_SHOWWINDOW = 0x0040
    [Win32]::SetWindowPos($handle, [IntPtr]::Zero, $X, $Y, $Width, $Height, $SWP_SHOWWINDOW) | Out-Null
}

# Get primary screen dimensions
Add-Type -AssemblyName System.Windows.Forms
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$halfWidth = [Math]::Floor($screen.Width / 2)
$halfHeight = [Math]::Floor($screen.Height / 2)



##################################################################
# Kill previous instances that may still be running
##################################################################

# Kill all other PowerShell processes (except the current one running this start script)
Get-Process powershell | Where-Object { $_.Id -ne $PID } | Stop-Process -Force

# Kill old instances if they are running
Write-Host "Killing any running instances of Prometheus, Loki, Tempo, and OTEL Collector..."
Stop-Process -Name "prometheus", "loki-windows-amd64", "tempo", "otelcol" -ErrorAction SilentlyContinue -Force



##################################################################
# Start the services in separate windows
##################################################################

# Prometheus - Top Left
Write-Host "Starting Prometheus..."
$promProc = Start-Process powershell.exe -ArgumentList "-NoExit -Command cd 'C:\Observability\prometheus'; .\prometheus.exe --config.file=prometheus.yml" -WindowStyle Normal -PassThru
Start-Sleep -Seconds 2
Set-WindowPosition -Process $promProc -X 0 -Y 0 -Width $halfWidth -Height $halfHeight

# Loki - Top Right
Write-Host "Starting Loki..."
$lokiProc = Start-Process powershell.exe -ArgumentList "-NoExit -Command cd 'C:\Observability\loki'; .\loki-windows-amd64.exe --config.file=loki-config.yaml" -WindowStyle Normal -PassThru
Start-Sleep -Seconds 2
Set-WindowPosition -Process $lokiProc -X $halfWidth -Y 0 -Width $halfWidth -Height $halfHeight

# Tempo - Bottom Left
Write-Host "Starting Tempo..."
$tempoProc = Start-Process powershell.exe -ArgumentList "-NoExit -Command cd 'C:\Observability\tempo'; .\tempo.exe --config.file=tempo.yaml" -WindowStyle Normal -PassThru
Start-Sleep -Seconds 2
Set-WindowPosition -Process $tempoProc -X 0 -Y $halfHeight -Width $halfWidth -Height $halfHeight

# Wait a bit before starting the OTEL Collector
Start-Sleep -Seconds 5

# OTEL Collector - Bottom Right
Write-Host "Starting OTEL Collector..."
$otelProc = Start-Process powershell.exe -ArgumentList "-NoExit -Command cd 'C:\Observability\otel'; .\otelcol-contrib.exe --config otelcol-config.yaml" -WindowStyle Normal -PassThru
Start-Sleep -Seconds 2
Set-WindowPosition -Process $otelProc -X $halfWidth -Y $halfHeight -Width $halfWidth -Height $halfHeight



##################################################################
# Start Grafana
##################################################################

# # Wait to allow collector to start before opening the browser
# Start-Sleep -Seconds 5

# # Write-Host "Opening Grafana in default browser..."
# Start-Process "http://localhost:3000"

Write-Host "All services have been started."